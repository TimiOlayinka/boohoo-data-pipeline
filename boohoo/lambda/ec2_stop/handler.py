import boto3
import os

ec2 = boto3.client("ec2")
INSTANCE_ID = os.environ["INSTANCE_ID"]

def lambda_handler(event, context):
    print(f"Stopping EC2 instance: {INSTANCE_ID}")
    ec2.stop_instances(InstanceIds=[INSTANCE_ID])
    return {"statusCode": 200, "body": f"Stopped {INSTANCE_ID}"}
