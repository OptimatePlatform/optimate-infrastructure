import boto3
import time
import os
import json
from botocore.exceptions import ClientError

rds = boto3.client('rds')
secretsmanager = boto3.client('secretsmanager')

def get_secret_value(secret_name):
    try:
        response = secretsmanager.get_secret_value(SecretId=secret_name)
        secret = response['SecretString']
        return json.loads(secret)
    except ClientError as e:
        print(f"Error getting secret: {e}")
        raise

def lambda_handler(event, context):
    common_master_creds = get_secret_value(os.environ['COMMON_RDS_MASTER_CREDS_SECRET_NAME'])

    db_instance_identifier = "shared-rds-mssql-" + str(int(time.time()))

    print("START OF CREATION")
    response = rds.create_db_instance(
        DBInstanceIdentifier=db_instance_identifier,
        MasterUsername=common_master_creds['username'],
        MasterUserPassword=common_master_creds['password'],

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
        DBSubnetGroupName=os.environ['RDS_SUBNET_GROUP_NAME']
    )

    # return {
    #     'dbInstanceIdentifier': db_instance_identifier,
    #     'host': db_instance['Endpoint']['Address'],
    #     'port': db_instance['Endpoint']['Port']
    # }
