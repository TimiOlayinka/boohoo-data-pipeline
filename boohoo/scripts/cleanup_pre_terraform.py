import boto3
import os

os.environ.setdefault("AWS_PROFILE", "playEngineer")
os.environ.setdefault("AWS_DEFAULT_REGION", "eu-west-2")

lam = boto3.client("lambda")
events = boto3.client("events")
iam = boto3.client("iam")

def cleanup():
    # 1. Delete EventBridge Rules
    print("Deleting EventBridge Rules...")
    rules = events.list_rules(NamePrefix="BoohooDaily")["Rules"]
    for r in rules:
        name = r["Name"]
        # Remove targets first
        targets = events.list_targets_by_rule(Rule=name)["Targets"]
        if targets:
            events.remove_targets(Rule=name, Ids=[t["Id"] for t in targets])
        events.delete_rule(Name=name)
        print(f"Deleted rule {name}")

    # 2. Delete Lambdas
    print("Deleting Lambdas...")
    functions = lam.list_functions()["Functions"]
    for f in functions:
        if f["FunctionName"].startswith("boohoo-"):
            lam.delete_function(FunctionName=f["FunctionName"])
            print(f"Deleted function {f['FunctionName']}")

    # 3. Delete IAM Role
    print("Deleting IAM Role...")
    role_name = "BoohooDataGeneratorRole"
    try:
        # Detach policies first
        policies = iam.list_attached_role_policies(RoleName=role_name)["AttachedPolicies"]
        for p in policies:
            iam.detach_role_policy(RoleName=role_name, PolicyArn=p["PolicyArn"])
        iam.delete_role(RoleName=role_name)
        print(f"Deleted role {role_name}")
    except iam.exceptions.NoSuchEntityException:
        pass

if __name__ == "__main__":
    cleanup()
