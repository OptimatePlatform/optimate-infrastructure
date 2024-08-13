import boto3
import os

dynamodb = boto3.client('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME')

def update_latest_rds_instance(rds_instance_id):
    try:
        dynamodb.put_item(
            TableName=table_name,
            Item={
                'instance_id': {'S': 'latest'},
                'rds_id': {'S': rds_instance_id},
            }
        )
        return True
    except Exception as e:
        print(f"Error updating DynamoDB: {e}")
        return False

def lambda_handler(event, context):
    rds_instance_id = event.get('instance_id')

    if not rds_instance_id:
        return {
            'statusCode': 400,
            'body': 'instance_id is required'
        }

    success = update_latest_rds_instance(rds_instance_id)

    if not success:
        return {
            'statusCode': 500,
            'body': 'Failed to update RDS instance in DynamoDB'
        }

    return {
        'statusCode': 200,
        'body': 'RDS instance updated successfully'
    }
