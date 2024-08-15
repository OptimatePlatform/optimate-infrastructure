import boto3
import time
import os
import json
from botocore.exceptions import ClientError

rds = boto3.client('rds')
secretsmanager = boto3.client('secretsmanager')

def get_secret_value(secret_name):
    try:
        secret_data = secretsmanager.get_secret_value(SecretId=secret_name)
        secret_string = secret_data['SecretString']
        return json.loads(secret_string)
    except ClientError as e:
        print(f"Error getting secret: {e}")
        raise



# def update_secret_value(secret_name, secret_key, key_value):
#     try:
#         original_secret = secretsmanager.get_secret_value(SecretId=secret_name)
#         updated_secret = original_secret.update({secret_key: key_value})
#         secretsmanager.update_secret(SecretId=secret_name, SecretString=json.dumps(updated_secret))
#     except ClientError as e:
#         print(f"Error with secret while updating: {e}")
#         raise

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

    common_rds_info_secret_name = os.environ['COMMON_RDS_INFO_SECRET_NAME']
    common_rds_info_secret = get_secret_value(common_rds_info_secret_name)
    common_rds_creds_secret = get_secret_value(os.environ['COMMON_RDS_MASTER_CREDS_SECRET_NAME'])

    db_instance_identifier = "shared-rds-mssql-" + str(int(time.time()))

    print("START OF CREATION")
    try:
        if (common_rds_info_secret['active_rds_creation_process'] == "true"):
            return
        else:
            create_rds_response = rds.create_db_instance(
                DBInstanceIdentifier=db_instance_identifier,
                MasterUsername=common_rds_creds_secret['username'],
                MasterUserPassword=common_rds_creds_secret['password'],

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
                        'Key': 'solution',
                        'Value': 'rds_scaling'
                    }
                ]
            )

            print(create_rds_response)
            if create_rds_response['DBInstance']['DBInstanceStatus'] == 'creating':
                print("RDS instance creation in process. Updating common_rds_info_secret")
                update_secret_key_value(common_rds_info_secret_name, "active_rds_creation_process", "true")
                update_secret_key_value(common_rds_info_secret_name, "new_rds_instance_id", create_rds_response['DBInstance']['DBInstanceIdentifier'])
            else:
                print("RDS instance creation interrapted by error. common_rds_info_secret value not updated.")

    except Exception as e:
        print(f"RDS instance creation interrapted by error: {e}")
