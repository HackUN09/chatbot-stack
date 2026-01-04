import os
import zipfile
import datetime
import shutil

# --- CONFIGURATION ---
PROJECT_ROOT = "."
BACKUP_DIR = os.path.join("ops", "backups", "snapshots")
IGNORE_DIRS = ["persistence", ".git", "node_modules", "db_core_data", "cache_core_data"]
IGNORE_EXT = [".log", ".txt", ".zip"]

def create_snapshot():
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    zip_name = f"genesis_snapshot_{timestamp}.zip"
    
    if not os.path.exists(BACKUP_DIR):
        os.makedirs(BACKUP_DIR)
        
    zip_path = os.path.join(BACKUP_DIR, zip_name)
    
    print(f"🚀 Creando snapshot: {zip_name}...")
    
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(PROJECT_ROOT):
            # Prune ignored directories
            dirs[:] = [d for d in dirs if d not in IGNORE_DIRS and not d.startswith(".")]
            
            for file in files:
                if any(file.endswith(ext) for ext in IGNORE_EXT):
                    continue
                if file == zip_name:
                    continue
                
                file_path = os.path.join(root, file)
                arc_name = os.path.relpath(file_path, PROJECT_ROOT)
                
                # Don't backup the backup folder itself
                if "ops/backups" in arc_name:
                    continue
                    
                zipf.write(file_path, arc_name)
                
    print(f"✅ Snapshot guardado en: {zip_path}")
    return zip_path

if __name__ == "__main__":
    try:
        create_snapshot()
    except Exception as e:
        print(f"❌ Error creando snapshot: {e}")
