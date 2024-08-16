import boto3
import os
import json
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
        else:
            print("RDS instance is not ready yet, terminating Lambda execution")

        return {
            'statusCode': 200,
            'body': json.dumps({'RDS status': rds_status})
        }
    except Exception as e:
        print(f"Error in lambda_handler: {e}")
        return {
            'statusCode': 500,
            'body': str(e)
        }
