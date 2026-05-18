import os
import zipfile
import io
import shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LAMBDA_DIR = os.path.join(SCRIPT_DIR, "..", "lambda")
DIST_DIR = os.path.join(SCRIPT_DIR, "..", "dist")
SHARED_DIR = os.path.join(LAMBDA_DIR, "shared")

def create_zip_for_lambda(function_folder):
    handler_path = os.path.join(LAMBDA_DIR, function_folder, "handler.py")
    zip_path = os.path.join(DIST_DIR, f"{function_folder}.zip")
    
    if not os.path.exists(handler_path):
        return None

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
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
    
    return zip_path

def main():
    if not os.path.exists(DIST_DIR):
        os.makedirs(DIST_DIR)
        
    # Clean previous builds
    for file in os.listdir(DIST_DIR):
        if file.endswith(".zip"):
            os.remove(os.path.join(DIST_DIR, file))

    dirs = [d for d in os.listdir(LAMBDA_DIR) if os.path.isdir(os.path.join(LAMBDA_DIR, d))]
    
    count = 0
    for d in dirs:
        if d in ["shared", "data_generator"]:
            continue
            
        zip_path = create_zip_for_lambda(d)
        if zip_path:
            print(f"Created {os.path.basename(zip_path)}")
            count += 1
            
    print(f"Build complete. {count} zip files generated in {DIST_DIR}/")

if __name__ == "__main__":
    main()
