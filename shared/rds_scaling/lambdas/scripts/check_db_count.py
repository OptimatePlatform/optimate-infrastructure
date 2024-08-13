import boto3
import os
import json

dynamodb = boto3.client('dynamodb')
secretsmanager = boto3.client('secretsmanager')
table_name = os.environ['DYNAMODB_TABLE_NAME']

def get_secret_value(secret_name):
    try:
        response = secretsmanager.get_secret_value(SecretId=secret_name)
        secret = response['SecretString']
        return json.loads(secret)
    except Exception as e:
        print(f"Error getting secret: {e}")
        return None

def get_rds_secret_name(instance_id):
    try:
        response = dynamodb.get_item(
            TableName=table_name,
            Key={
                'instance_id': {'S': instance_id}
            }
        )
        item = response.get('Item')
        if item:
            return item.get('secret_name', {}).get('S')
        return None
    except Exception as e:
        print(f"Error getting RDS secret name: {e}")
        return None

def lambda_handler(event, context):
    rds_instance_id = event.get('instance_id')

    if not rds_instance_id:
        return {
            'statusCode': 400,
            'body': 'instance_id is required'
        }

    secret_name = get_rds_secret_name(rds_instance_id)
    if not secret_name:
        return {
            'statusCode': 500,
            'body': 'Failed to get secret name from DynamoDB'
        }

    secret_value = get_secret_value(secret_name)
    if not secret_value:
        return {
            'statusCode': 500,
            'body': 'Failed to get secret value'
        }

    print(f"RDS Instance ID: {rds_instance_id}")
    print(f"Secret Value: {secret_value}")

    return {
        'statusCode': 200,
        'body': 'RDS instance updated'
    }
