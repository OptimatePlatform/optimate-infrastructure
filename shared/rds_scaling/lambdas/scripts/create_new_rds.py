import boto3
import time
import os
import json
from botocore.exceptions import ClientError

rds = boto3.client('rds')
secretsmanager = boto3.client('secretsmanager')
dynamodb = boto3.resource('dynamodb')

def get_secret_value(secret_name):
    try:
        secret_data = secretsmanager.get_secret_value(SecretId=secret_name)
        secret = secret_data['SecretString']
        return json.loads(secret)
    except ClientError as e:
        print(f"Error getting secret: {e}")
        raise

def update_dynamodb_item_active_rds_creation_process(table_name):
    table = dynamodb.Table(table_name)
    scaned_table = table.scan()
    items = scaned_table['Items']
    rds_instance_host = items[0].get('rds_instance_host')

    update_active_rds_creation_process = table.update_item(
        Key={
            'rds_instance_host': rds_instance_host
        },
        UpdateExpression="set active_rds_creation_process = :true_value",
        ConditionExpression="attribute_exists(rds_instance_host) AND active_rds_creation_process = :false_value",
        ExpressionAttributeValues={
            ':true_value': "true",
            ':false_value': "false"
        },
        ReturnValues="UPDATED_NEW"
    )

    return update_active_rds_creation_process


def update_dynamodb_item_new_rds_instance_id(table_name, rds_instance_id):
    table = dynamodb.Table(table_name)
    scaned_table = table.scan()
    items = scaned_table['Items']
    rds_instance_host = items[0].get('rds_instance_host')

    update_new_rds_instance_id = table.update_item(
        Key={
            'rds_instance_host': rds_instance_host
        },
        UpdateExpression="set new_rds_instance_id = :new_value",
        ConditionExpression="attribute_exists(rds_instance_host) AND new_rds_instance_id = :default_value",
        ExpressionAttributeValues={
            ':new_value': rds_instance_id,
            ':default_value': "none"
        },
        ReturnValues="UPDATED_NEW"
    )

    return update_new_rds_instance_id


def get_latest_rds_info_dynamodb(dynamodb_table_name, attribute_name):
    try:
        table = dynamodb.Table(dynamodb_table_name)

        scaned_table = table.scan()
        data = scaned_table['Items']

        attribute_value = data[0].get(attribute_name)

        return attribute_value
    except ClientError as e:
        print(f"Error getting data form DynamoDB table: {e}")
        raise



def lambda_handler(event, context):
    common_master_creds = get_secret_value(os.environ['COMMON_RDS_MASTER_CREDS_SECRET_NAME'])

    db_instance_identifier = "shared-rds-mssql-" + str(int(time.time()))

    print("START OF CREATION")
    try:
        current_value_of_active_rds_creation_process = get_latest_rds_info_dynamodb()
        if (current_value_of_active_rds_creation_process == "true"):
            return
        else:
            create_rds_response = rds.create_db_instance(
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
                print("RDS instance creation in process. Updating DynamoDB")
                update_dynamodb_item_active_rds_creation_process(os.environ['DYNAMODB_TABLE_NAME'])
                update_dynamodb_item_new_rds_instance_id((os.environ['DYNAMODB_TABLE_NAME']), create_rds_response['DBInstance']['DBInstanceIdentifier'])
            else:
                print("RDS instance creation interrapted by error. DynamoDB item not updated.")

    except Exception as e:
        print(f"RDS instance creation interrapted by error: {e}")
