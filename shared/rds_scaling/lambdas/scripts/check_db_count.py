import boto3
import os
import json
import pymssql
from botocore.exceptions import ClientError
import time



dynamodb = boto3.resource('dynamodb')
secretsmanager = boto3.client('secretsmanager')
table_name = os.environ['DYNAMODB_TABLE_NAME']


def get_secret_value(secret_name):
    try:
        response = secretsmanager.get_secret_value(SecretId=secret_name)
        secret = response['SecretString']
        return json.loads(secret)
    except ClientError as e:
        print(f"Error getting secret: {e}")
        raise


def get_latest_rds_info():
    try:
        table = dynamodb.Table(table_name)

        response = table.scan()
        data = response['Items']

        secret_name = data[0].get('secret_name')
        instance_id = data[0].get('instance_id')

        return instance_id, secret_name
    except ClientError as e:
        print(f"Error getting latest RDS info: {e}")
        raise


def check_database_count(rds_instance_id, secret_name):
    secret_value = get_secret_value(secret_name)
    db_host = secret_value['host']
    db_user = secret_value['username']
    db_password = secret_value['password']

    for attempt in range(3):
        try:
            conn = pymssql.connect(server=db_host, user=db_user, password=db_password)
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM sys.databases")
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



def lambda_handler(event, context):
    try:
        rds_instance_id, secret_name = get_latest_rds_info()

        if not rds_instance_id or not secret_name:
            return {
                'statusCode': 404,
                'body': 'Latest RDS instance or secret name not found in DynamoDB'
            }

        db_count = check_database_count(rds_instance_id, secret_name)

        return {
            'statusCode': 200,
            'body': json.dumps({'db_count': db_count})
        }
    except Exception as e:
        print(f"Error in lambda_handler: {e}")
        return {
            'statusCode': 500,
            'body': str(e)
        }
