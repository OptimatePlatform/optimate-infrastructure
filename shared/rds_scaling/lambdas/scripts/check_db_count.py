import boto3
import os
import json
import time
import pymssql
from botocore.exceptions import ClientError


rds = boto3.client('rds')
secretsmanager = boto3.client('secretsmanager')
step_functions = boto3.client('stepfunctions')


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


def check_database_count(rds_instance_host, rds_master_username, rds_master_password):
    db_host = rds_instance_host
    db_user = rds_master_username
    db_password = rds_master_password

    for attempt in range(3):
        try:
            conn = pymssql.connect(server=db_host, user=db_user, password=db_password)
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM sys.databases WHERE database_id > 5") # list all databases except 4 system and 1 aws custom databases
            db_count = cursor.fetchone()[0]
            conn.close()
            return db_count
        except pymssql.DatabaseError as e:
            print(f"Database error: {e}")
            time.sleep(10)
        except Exception as e:
            print(f"Unexpected error: {e}")
            raise

    raise Exception("Failed to connect to database after multiple attempts")


def create_rds_instance(rds_instance_name, master_username, master_password):
    create_rds_response = rds.create_db_instance(
        DBInstanceIdentifier=rds_instance_name,
        MasterUsername=master_username,
        MasterUserPassword=master_password,

        DBInstanceClass=os.environ['RDS_INSTANCE_CLASS'],
        Port=int(os.environ['RDS_PORT']),
        Engine=os.environ['RDS_ENGINE'],
        EngineVersion=os.environ['RDS_ENGINE_VERSION'],
        LicenseModel=os.environ['RDS_LICENSE_MODEL'],
        StorageType=os.environ['RDS_STORAGE_TYPE'],
        AllocatedStorage=int(os.environ['RDS_ALLOCATED_STORAGE']),
        MaxAllocatedStorage=int(os.environ['RDS_MAX_ALLOCATED_STORAGE']),
        DeletionProtection=bool(os.environ['RDS_DELETION_PROTECTION']),
        VpcSecurityGroupIds=[os.environ['RDS_SECURITY_GROUP_ID']],
        DBSubnetGroupName=os.environ['RDS_SUBNET_GROUP_NAME'],
        Tags=[
            {
                'Key': 'Solution',
                'Value': 'rds_scaling'
            }
        ]
    )
    return create_rds_response


def invoke_step_function():
    state_machine_arn = os.environ['STATE_MACHINE_ARN']

    try:
        response = step_functions.start_execution(
            stateMachineArn=state_machine_arn,
            input="{}"  # You can pass any necessary input in JSON format here
        )

        print(f"Started Step Function execution with ARN: {response['executionArn']}")

        return {
            'statusCode': 200,
            'body': f"Started Step Function execution with ARN: {response['executionArn']}"
        }
    except Exception as e:
        print(f"Error starting Step Function: {e}")
        return {
            'statusCode': 500,
            'body': f"Error starting Step Function: {e}"
        }


def lambda_handler(event, context):
    try:
        common_rds_info_secret_name = os.environ['COMMON_RDS_INFO_SECRET_NAME']
        common_rds_info_secret = get_secret_value(common_rds_info_secret_name)

        rds_instance_host = common_rds_info_secret['rds_instance_host']
        rds_creds_secret_name = common_rds_info_secret['rds_secret_name']

        if not rds_instance_host or not rds_creds_secret_name:
            return {
                'statusCode': 404,
                'body': 'Latest RDS Host or secret name not found in common_rds_info_secret'
            }

        common_rds_creds_secret = get_secret_value(rds_creds_secret_name)
        rds_master_username = common_rds_creds_secret['username']
        rds_master_password = common_rds_creds_secret['password']


        db_count_per_rds_instance = check_database_count(rds_instance_host, rds_master_username, rds_master_password)
        if db_count_per_rds_instance > int(os.environ['DB_COUNT_PER_RDS_TRESHOLD']):
            try:
                if (common_rds_info_secret['active_rds_creation_process'] == "true"):
                    print("Exit. Due to active_rds_creation_process = true")
                    return
                else:
                    new_rds_creds_secret = get_secret_value(os.environ['COMMON_RDS_MASTER_CREDS_SECRET_NAME'])
                    new_rds_master_username = new_rds_creds_secret['username']
                    new_rds_master_password = new_rds_creds_secret['password']

                    db_instance_identifier = "shared-rds-mssql-" + str(int(time.time()))
                    print("Start creation of new RDS instance")
                    new_rds_instance_response = create_rds_instance(db_instance_identifier, new_rds_master_username, new_rds_master_password)
                    if new_rds_instance_response['DBInstance']['DBInstanceStatus'] == 'creating': # IF rds creating process start withou errors
                        print("RDS instance creation in process. Updating common_rds_info_secret")
                        update_secret_key_value(common_rds_info_secret_name, "active_rds_creation_process", "true")
                        update_secret_key_value(common_rds_info_secret_name, "new_rds_instance_id", new_rds_instance_response['DBInstance']['DBInstanceIdentifier'])
                        invoke_step_function() # start checking RDS instance status
                    else:
                        print("RDS instance creation interrapted by error. common_rds_info_secret value not updated.")
            except Exception as e:
                print(f"RDS instance creation interrapted by error: {e}")
        else:
            print(f"Exit. Due to db count ({db_count_per_rds_instance}) threshold not breached")

    except Exception as e:
        print(f"Error in lambda_handler: {e}")
        return {
            'statusCode': 500,
            'body': str(e)
        }
