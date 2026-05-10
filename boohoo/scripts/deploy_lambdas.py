import boto3
import os
import zipfile
import io
import time
import json

if not os.environ.get("GITHUB_ACTIONS"):
    os.environ.setdefault("AWS_PROFILE", "playEngineer")

os.environ.setdefault("AWS_DEFAULT_REGION", "eu-west-2")

iam = boto3.client("iam")
lam = boto3.client("lambda")

ROLE_NAME = "BoohooDataGeneratorRole"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LAMBDA_DIR = os.path.join(SCRIPT_DIR, "..", "lambda")
SHARED_DIR = os.path.join(LAMBDA_DIR, "shared")

def get_or_create_role():
    try:
        resp = iam.get_role(RoleName=ROLE_NAME)
        role_arn = resp["Role"]["Arn"]
        print(f"Using existing role: {role_arn}")
    except iam.exceptions.NoSuchEntityException:
        print(f"Creating role: {ROLE_NAME}")
        trust_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {"Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}
            ]
        }
        resp = iam.create_role(
            RoleName=ROLE_NAME,
            AssumeRolePolicyDocument=json.dumps(trust_policy)
        )
        role_arn = resp["Role"]["Arn"]
        
        iam.attach_role_policy(
            RoleName=ROLE_NAME,
            PolicyArn="arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        )
        iam.attach_role_policy(
            RoleName=ROLE_NAME,
            PolicyArn="arn:aws:iam::aws:policy/AmazonS3FullAccess"
        )
        print("Waiting for role to propagate...")
        time.sleep(10)
        
    return role_arn

def create_zip(handler_path):
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        # Add handler
        zf.write(handler_path, arcname="handler.py")
        
        # Add shared files
        for f in ["utils.py", "handler_logic.py"]:
            shared_file = os.path.join(SHARED_DIR, f)
            if os.path.exists(shared_file):
                zf.write(shared_file, arcname=f)
                
        # Add config directory
        config_dir = os.path.join(SHARED_DIR, "config")
        if os.path.exists(config_dir):
            for root, dirs, files in os.walk(config_dir):
                for file in files:
                    if file.endswith(".py"):
                        file_path = os.path.join(root, file)
                        arcname = os.path.join("config", os.path.relpath(file_path, config_dir))
                        zf.write(file_path, arcname=arcname)
                
    zip_buffer.seek(0)
    return zip_buffer.read()

def deploy_function(function_name, role_arn, zip_bytes):
    try:
        lam.get_function(FunctionName=function_name)
        print(f"Updating function: {function_name}")
        lam.update_function_code(
            FunctionName=function_name,
            ZipFile=zip_bytes
        )
    except lam.exceptions.ResourceNotFoundException:
        print(f"Creating function: {function_name}")
        lam.create_function(
            FunctionName=function_name,
            Runtime="python3.11",
            Role=role_arn,
            Handler="handler.lambda_handler",
            Code={"ZipFile": zip_bytes},
            Timeout=300,
            MemorySize=512
        )

def main():
    role_arn = get_or_create_role()
    
    dirs = [d for d in os.listdir(LAMBDA_DIR) if os.path.isdir(os.path.join(LAMBDA_DIR, d))]
    
    for d in dirs:
        if d in ["shared", "data_generator"]:
            continue
            
        function_name = f"boohoo-{d.replace('_', '-')}"
        handler_path = os.path.join(LAMBDA_DIR, d, "handler.py")
        
        if not os.path.exists(handler_path):
            continue
            
        zip_bytes = create_zip(handler_path)
        deploy_function(function_name, role_arn, zip_bytes)
        
    print("\nDeployment complete.")

if __name__ == "__main__":
    main()
