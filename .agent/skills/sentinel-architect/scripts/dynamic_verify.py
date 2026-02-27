import subprocess
import json
import time

class SentinelArchitectEngine:
    """
    Formalized Engine for System Integrity Verification.
    Applies Discrete Topology checks to the Docker stack.
    """
    
    EXPECTED_CONTAINERS = [
        "db_core", "cache_core", "app_evolution", 
        "chatwoot", "n8n", "minio_core"
    ]
    
    NETWORK_NAME = "secure-net"

    def get_container_state(self, name):
        try:
            cmd = ["docker", "inspect", name, "--format", "{{json .State}}"]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return json.loads(result.stdout)
        except:
            return None

    def calculate_health_index(self):
        print(f"\033[38;5;51m[SYSTEM_ARCHITECT] Initiating Formal State Verification...\033[0m")
        time.sleep(0.5)
        
        active_nodes = 0
        total_nodes = len(self.EXPECTED_CONTAINERS)
        drifts = []

        for container in self.EXPECTED_CONTAINERS:
            state = self.get_container_state(container)
            if state and state.get("Status") == "running":
                active_nodes += 1
                print(f"  \033[38;5;46m✔\033[0m Node {container:15} : SYNC_ACTIVE")
            else:
                drifts.append(container)
                print(f"  \033[38;5;198m✘\033[0m Node {container:15} : STATE_DRIFT")

        # Formal Integrity Calculation (Binary Entropy Representation)
        integrity_score = (active_nodes / total_nodes) * 100
        
        print("\n\033[38;5;129m[ARCHITECTURAL_METRICS]\033[0m")
        print(f"  Density Index: {active_nodes}/{total_nodes}")
        print(f"  Integrity Score: {integrity_score:.2f}%")
        
        if integrity_score == 100:
            print(f"\033[38;5;46m  SYSTEM_STATE: ABSOLUTE_EQUILIBRIUM\033[0m")
        else:
            print(f"\033[38;5;226m  SYSTEM_STATE: RECOVERY_REQUIRED\033[0m")
            print(f"  Detected Drifts: {', '.join(drifts)}")

if __name__ == "__main__":
    engine = SentinelArchitectEngine()
    engine.calculate_health_index()
