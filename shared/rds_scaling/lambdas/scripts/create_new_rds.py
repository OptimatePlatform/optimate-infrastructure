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

    response = rds.create_db_instance(
        DBInstanceIdentifier=db_instance_identifier,
        MasterUsername=os.environ['MASTER_USERNAME'],
        MasterUserPassword=os.environ['MASTER_PASSWORD'],
        DBInstanceClass=os.environ['DB_INSTANCE_CLASS'],
        Engine=os.environ['DB_ENGINE'],
        AllocatedStorage=int(os.environ['ALLOCATED_STORAGE']),
        VpcSecurityGroupIds=[os.environ['SECURITY_GROUP']],
        DBSubnetGroupName=os.environ['DB_SUBNET_GROUP_NAME']
    )

    db_instance_arn = response['DBInstance']['DBInstanceArn']

    waiter = rds.get_waiter('db_instance_available')
    waiter.wait(DBInstanceIdentifier=db_instance_identifier)

    db_instance = rds.describe_db_instances(DBInstanceIdentifier=db_instance_identifier)['DBInstances'][0]

    return {
        'dbInstanceIdentifier': db_instance_identifier,
        'host': db_instance['Endpoint']['Address'],
        'port': db_instance['Endpoint']['Port']
    }
