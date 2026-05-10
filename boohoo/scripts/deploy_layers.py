import boto3, time, os, glob, re

os.environ.setdefault("AWS_PROFILE", "playEngineer")
os.environ.setdefault("AWS_DEFAULT_REGION", "eu-west-2")

client = boto3.client("redshift-data")
WORKGROUP = "boohoo-workgroup"
DB = "boohoo_dwh"

def run_sql(sql, desc=""):
    try:
        resp = client.execute_statement(WorkgroupName=WORKGROUP, Database=DB, Sql=sql)
        stmt_id = resp["Id"]
        print(f"  [{desc}] submitted: {stmt_id}")
        while True:
            time.sleep(2)
            status = client.describe_statement(Id=stmt_id)
            s = status["Status"]
            if s in ("FINISHED",):
                print(f"  [{desc}] OK {s}")
                return True
            elif s in ("FAILED", "ABORTED"):
                print(f"  [{desc}] FAIL {s}: {status.get('Error', 'unknown')}")
                return False
    except Exception as e:
        print(f"  [{desc}] Exception: {e}")
        return False

def deploy_layer(layer_path):
    print(f"\n--- Deploying {layer_path} ---")
    files = glob.glob(f"{layer_path}/**/*.sql", recursive=True)
    for fpath in files:
        with open(fpath, "r", encoding="utf-8") as f:
            sql = f.read()

        # Extract variables from headers like: --@variable "dev_odl" ${SCHEMA_ODL}
        # and replace them in the SQL text
        lines = sql.splitlines()
        for line in lines:
            if line.startswith("--@variable"):
                parts = line.split()
                if len(parts) >= 3:
                    val = parts[1].strip('"\'')
                    var = parts[2].strip()
                    # Replace variable with value
                    sql = sql.replace(var, val)
        
        # Run the SQL
        success = run_sql(sql, desc=os.path.basename(fpath))
        if not success:
            print(f"Deployment failed on {fpath}")
            return False
            
    return True

if __name__ == "__main__":
    layers_dir = "d:/BellosData/aws-data-portfolio/boohoo/layers"
    for layer in ["rdl", "odl", "adl", "udl"]:
        path = os.path.join(layers_dir, layer)
        if os.path.exists(path):
            if not deploy_layer(path):
                print("Aborting deployment due to error.")
                break
    print("\nDeployment complete.")
