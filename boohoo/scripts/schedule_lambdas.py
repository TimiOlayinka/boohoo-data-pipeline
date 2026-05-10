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
    print(f"Creating/Updating EventBridge Rule: {RULE_NAME}")
    
    # Create the rule
    rule_response = events.put_rule(
        Name=RULE_NAME,
        ScheduleExpression=SCHEDULE,
        State='ENABLED',
        Description="Daily trigger for Boohoo synthetic data generation Lambdas"
    )
    rule_arn = rule_response["RuleArn"]
    print(f"Rule ARN: {rule_arn}")
    
    # Get all lambda function names
    dirs = [d for d in os.listdir(LAMBDA_DIR) if os.path.isdir(os.path.join(LAMBDA_DIR, d))]
    targets = []
    
    for d in dirs:
        if d in ["shared", "data_generator"]:
            continue
            
        function_name = f"boohoo-{d.replace('_', '-')}"
        
        try:
            # Get Lambda ARN
            fn_info = lam.get_function(FunctionName=function_name)
            fn_arn = fn_info["Configuration"]["FunctionArn"]
            
            # Prepare target
            targets.append({
                "Id": function_name,
                "Arn": fn_arn
            })
            
            # Grant EventBridge permission to invoke the Lambda
            try:
                lam.add_permission(
                    FunctionName=function_name,
                    StatementId=f"AllowEventBridgeInvoke_{RULE_NAME}",
                    Action="lambda:InvokeFunction",
                    Principal="events.amazonaws.com",
                    SourceArn=rule_arn
                )
                print(f"Granted EventBridge invoke permission for {function_name}")
            except lam.exceptions.ResourceConflictException:
                # Permission already exists
                pass
                
        except lam.exceptions.ResourceNotFoundException:
            print(f"Warning: Function {function_name} not found in AWS. Skipping.")
            
    if targets:
        # Attach targets to rule
        print(f"Attaching {len(targets)} targets to rule...")
        events.put_targets(
            Rule=RULE_NAME,
            Targets=targets
        )
        print("Successfully attached all targets.")
    else:
        print("No targets found to attach.")

if __name__ == "__main__":
    setup_schedule()
