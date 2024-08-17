import boto3
import os
import json
import time
import pymssql
from botocore.exceptions import ClientError


rds_client = boto3.client('rds')
secretsmanager = boto3.client('secretsmanager')


def check_rds_status(instance_id):
    try:
        get_rds_info = rds_client.describe_db_instances(DBInstanceIdentifier=instance_id)
        rds_status = get_rds_info['DBInstances'][0]['DBInstanceStatus']
        return rds_status
    except ClientError as e:
        print(f"Error checking RDS status: {e}")
        raise

def get_secret_value(secret_name):
    try:
        secret_data = secretsmanager.get_secret_value(SecretId=secret_name)
        secret_string = secret_data['SecretString']
        return json.loads(secret_string)
    except ClientError as e:
        print(f"Error getting secret: {e}")
        raise


def update_secret_key_value(secret_name, key, new_value):
    try:
        get_secret_value_response = secretsmanager.get_secret_value(SecretId=secret_name)
        secret_string = get_secret_value_response['SecretString']
        secret_dict = json.loads(secret_string)

        if key in secret_dict:
            secret_dict[key] = new_value
        else:
            print(f"Key '{key}' not found in secret '{secret_name}'.")
            return

        updated_secret_string = json.dumps(secret_dict)
        secretsmanager.update_secret(SecretId=secret_name, SecretString=updated_secret_string)

        print(f"Key '{key}' successfully updated in secret '{secret_name}'.")

    except Exception as e:
        print(f"Error updating the secret: {e}")


def update_database_table(rds_instance_host, rds_master_username, rds_master_password, db_name, new_rds_host, new_rds_password):
    for attempt in range(3):
        try:
            conn = pymssql.connect(server=rds_instance_host, user=rds_master_username, password=rds_master_password, database=db_name)
            cursor = conn.cursor()

            cursor.execute("""INSERT INTO Instances(Id, Name, Password) VALUES (NEWID(), %s, %s)""", (new_rds_host, new_rds_password))

            conn.commit()
            conn.close()

            return "Insert to Service Database successful"

        except pymssql.DatabaseError as e:
            print(f"Database error: {e}")
            time.sleep(10)

        except Exception as e:
            print(f"Unexpected error: {e}")
            raise
    raise Exception("Failed to connect to database after multiple attempts")


def lambda_handler(event, context):
    try:
        common_rds_info_secret_name = os.environ['COMMON_RDS_INFO_SECRET_NAME']
        common_rds_creds_secret_name = os.environ['COMMON_RDS_MASTER_CREDS_SECRET_NAME']

        common_rds_info_secret = get_secret_value(common_rds_info_secret_name)
        new_rds_instance_id = common_rds_info_secret['new_rds_instance_id']
        rds_status = check_rds_status(new_rds_instance_id)
        print(f"RDS instance status: {rds_status}")

        if rds_status == 'available':
            get_rds_info = rds_client.describe_db_instances(DBInstanceIdentifier=new_rds_instance_id)
            rds_endpoint = get_rds_info['DBInstances'][0]['Endpoint']['Address']

            update_secret_key_value(common_rds_info_secret_name, "active_rds_creation_process", "false")
            update_secret_key_value(common_rds_info_secret_name, "rds_instance_host", rds_endpoint)
            update_secret_key_value(common_rds_info_secret_name, "rds_secret_name", common_rds_creds_secret_name)
            update_secret_key_value(common_rds_info_secret_name, "new_rds_instance_id", "none")
            print("RDS instance is ready, common_rds_info_secret updated")


            service_rds_secret_name = os.environ['SERVICE_RDS_SECRET_NAME']
            service_rds_host = get_secret_value(service_rds_secret_name)['host']
            service_rds_username = get_secret_value(service_rds_secret_name)['username']
            service_rds_password = get_secret_value(service_rds_secret_name)['password']

            new_rds_secret = get_secret_value(common_rds_info_secret_name)['rds_secret_name']
            new_rds_password = get_secret_value(new_rds_secret)['password']
            print(update_database_table(service_rds_host, service_rds_username, service_rds_password, os.environ['SERVICE_DATABASE_NAME'], rds_endpoint, new_rds_password))

            return {
                'rds_status': 'available'
            }
        else:
            print("RDS instance is not ready yet, terminating Lambda execution")
            return {
                'rds_status': 'not ready'
            }
    except Exception as e:
        print(f"Error in lambda_handler: {e}")
        return {
            'error': str(e)
        }
