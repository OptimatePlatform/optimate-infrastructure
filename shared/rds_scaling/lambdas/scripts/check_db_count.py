import boto3
import os
import json
import pymssql
from botocore.exceptions import ClientError
import time


secretsmanager = boto3.client('secretsmanager')


def get_secret_value(secret_name):
    try:
        secret_data = secretsmanager.get_secret_value(SecretId=secret_name)
        secret_string = secret_data['SecretString']
        return json.loads(secret_string)
    except ClientError as e:
        print(f"Error getting secret: {e}")
        raise



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



def lambda_handler(event, context):
    try:
        common_rds_info_secret = get_secret_value(os.environ['COMMON_RDS_INFO_SECRET_NAME'])
        rds_instance_host = common_rds_info_secret['rds_instance_host']
        rds_creds_secret_name = common_rds_info_secret['rds_secret_name']

        common_rds_creds_secret = get_secret_value(rds_creds_secret_name)
        rds_master_username = common_rds_creds_secret['username']
        rds_master_password = common_rds_creds_secret['password']

        if not rds_instance_host or not rds_creds_secret_name:
            return {
                'statusCode': 404,
                'body': 'Latest RDS Host or secret name not found in common_rds_info_secret'
            }

        db_count = check_database_count(rds_instance_host, rds_master_username, rds_master_password)

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
