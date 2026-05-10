import boto3
import os

if not os.environ.get("GITHUB_ACTIONS"):
    os.environ.setdefault("AWS_PROFILE", "playEngineer")

os.environ.setdefault("AWS_DEFAULT_REGION", "eu-west-2")

events = boto3.client("events")
lam = boto3.client("lambda")

RULE_NAME = "BoohooDailyDataGeneration"
SCHEDULE = "cron(0 0 * * ? *)"  # Midnight UTC daily
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LAMBDA_DIR = os.path.join(SCRIPT_DIR, "..", "lambda")

def setup_schedule():
    dirs = [d for d in os.listdir(LAMBDA_DIR) if os.path.isdir(os.path.join(LAMBDA_DIR, d))]
    
    for d in dirs:
        if d in ["shared", "data_generator"]:
            continue
            
        function_name = f"boohoo-{d.replace('_', '-')}"
        rule_name = f"BoohooDailySchedule_{d}"
        
        try:
            # Get Lambda ARN
            fn_info = lam.get_function(FunctionName=function_name)
            fn_arn = fn_info["Configuration"]["FunctionArn"]
            
            print(f"Creating/Updating EventBridge Rule: {rule_name}")
            # Create the rule
            rule_response = events.put_rule(
                Name=rule_name,
                ScheduleExpression=SCHEDULE,
                State='ENABLED',
                Description=f"Daily trigger for {function_name}"
            )
            rule_arn = rule_response["RuleArn"]
            
            # Grant EventBridge permission to invoke the Lambda
            try:
                lam.add_permission(
                    FunctionName=function_name,
                    StatementId=f"AllowEventBridgeInvoke",
                    Action="lambda:InvokeFunction",
                    Principal="events.amazonaws.com",
                    SourceArn=rule_arn
                )
                print(f"Granted EventBridge invoke permission for {function_name}")
            except lam.exceptions.ResourceConflictException:
                pass
                
            # Attach target to rule
            events.put_targets(
                Rule=rule_name,
                Targets=[{
                    "Id": function_name,
                    "Arn": fn_arn
                }]
            )
            print(f"Successfully attached {function_name} to {rule_name}.")
                
        except lam.exceptions.ResourceNotFoundException:
            print(f"Warning: Function {function_name} not found in AWS. Skipping.")
            
    print("Scheduling complete.")

if __name__ == "__main__":
    setup_schedule()
