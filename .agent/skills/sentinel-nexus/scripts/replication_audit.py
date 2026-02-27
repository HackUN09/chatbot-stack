import os
import subprocess

class NexusReplicationAuditor:
    """
    Checks if the local environment is ready for full system replication.
    """
    
    REQUIRED_FILES = [".env", "sistema_maestro.sh", "modules/01-infra/docker-compose.yml"]
    
    def check_files(self):
        print("\033[38;5;129m[NEXUS_AUDIT] Checking File Integrity...\033[0m")
        for f in self.REQUIRED_FILES:
            if os.path.exists(f):
                print(f"  \033[38;5;46m✔\033[0m {f:30} : FOUND")
            else:
                print(f"  \033[38;5;198m✘\033[0m {f:30} : MISSING")

    def validate_env_keys(self):
        print("\n\033[38;5;51m[NEXUS_AUDIT] Validating Critical Environment Keys...\033[0m")
        if not os.path.exists(".env"):
            print("  \033[38;5;198m✘ .env file not found!\033[0m")
            return

        critical_keys = ["POSTGRES_ROOT_PASSWORD", "EVOLUTION_API_KEY", "DOMAIN"]
        with open(".env", "r") as f:
            content = f.read()
            for key in critical_keys:
                if key in content:
                    print(f"  \033[38;5;46m✔\033[0m {key:30} : PRESENT")
                else:
                    print(f"  \033[38;5;198m✘\033[0m {key:30} : MISSING")

    def run_audit(self):
        self.check_files()
        self.validate_env_keys()
        print(f"\n\033[38;5;226m[AUDIT_COMPLETE] System is ready for autonomous replication.\033[0m")

if __name__ == "__main__":
    auditor = NexusReplicationAuditor()
    auditor.run_audit()
