import boto3
import os
import json
from botocore.exceptions import ClientError

rds_client = boto3.client('rds')
dynamodb = boto3.resource('dynamodb')

default_rds_secret_name = os.environ['DEFAULT_RDS_SECRET_NAME']

def check_rds_status(instance_id):
    try:
        response = rds_client.describe_db_instances(DBInstanceIdentifier=instance_id)
        status = response['DBInstances'][0]['DBInstanceStatus']
        return status
    except ClientError as e:
        print(f"Error checking RDS status: {e}")
        raise


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


def update_dynamodb_table(table_name, rds_instance_id):
    try:
        table = dynamodb.Table(table_name)
        table.update_item(
            Key={
                'instance_id': 'latest'
            },
            UpdateExpression="SET rds_instance_host = :host, rds_secret_name = :secret_name, active_rds_creation_process = :active, new_rds_instance_id = :new_instance_id",
            ExpressionAttributeValues={
                ':host': rds_instance_id,
                ':secret_name': default_rds_secret_name,
                ':active': "False",
                ':new_instance_id': "None"
            }
        )
        print("DynamoDB table updated successfully")
    except ClientError as e:
        print(f"Error updating DynamoDB table: {e}")
        raise


def lambda_handler(event, context):
    try:
        rds_instance_id = get_latest_rds_info_dynamodb(os.environ['DYNAMODB_TABLE_NAME'], "new_rds_instance_id")
        status = check_rds_status(rds_instance_id)
        print(f"RDS instance status: {status}")

        if status == 'available':
            update_dynamodb_table(os.environ['DYNAMODB_TABLE_NAME'], rds_instance_id)
            print("RDS instance is ready, DynamoDB table updated")
        else:
            print("RDS instance is not ready yet, terminating Lambda execution")

        return {
            'statusCode': 200,
            'body': json.dumps({'status': status})
        }
    except Exception as e:
        print(f"Error in lambda_handler: {e}")
        return {
            'statusCode': 500,
            'body': str(e)
        }
