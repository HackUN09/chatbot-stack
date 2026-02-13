import json
import urllib.request
import time
import concurrent.futures
import threading

# --- CONFIGURATION (NEXUS SYNC) ---
BASE_URL = "http://localhost:8080"
API_KEY = "YOUR_API_KEY" # Placeholder - to be extracted from ENV
INSTANCE_NAME = "test"
CONCURRENCY = 50 # Threads
TOTAL_MESSAGES = 500

# --- METRIC TRACKER ---
stats = {
    "sent": 0,
    "failed": 0,
    "latencies": []
}
lock = threading.Lock()

def get_api_key():
    try:
        with open(".env", "r") as f:
            for line in f:
                if "EVOLUTION_API_KEY=" in line:
                    return line.split("=")[1].strip()
    except: return API_KEY

def send_message(msg_id):
    api_key = get_api_key()
    url = f"{BASE_URL}/message/sendText/{INSTANCE_NAME}"
    headers = {
        "Content-Type": "application/json",
        "apikey": api_key
    }
    payload = {
        "number": "573000000000",
        "text": f"SENTINEL STRESS TEST - MSG #{msg_id} - {time.time()}"
    }
    
    start_time = time.time()
    try:
        req = urllib.request.Request(url, data=json.dumps(payload).encode(), headers=headers)
        with urllib.request.urlopen(req, timeout=5) as response:
            latency = time.time() - start_time
            with lock:
                stats["sent"] += 1
                stats["latencies"].append(latency)
    except Exception as e:
        with lock:
            stats["failed"] += 1

def run_stress_test():
    print(f"🚀 INICIANDO Aegis Stress v11.0: Enjambre de {CONCURRENCY} hilos...")
    print(f"🎯 Objetivo: {TOTAL_MESSAGES} mensajes hacia {INSTANCE_NAME}")
    
    start_total = time.time()
    with concurrent.futures.ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
        futures = [executor.submit(send_message, i) for i in range(TOTAL_MESSAGES)]
        concurrent.futures.wait(futures)
    
    end_total = time.time()
    duration = end_total - start_total
    
    avg_latency = sum(stats["latencies"]) / len(stats["latencies"]) if stats["latencies"] else 0
    throughput = stats["sent"] / duration if duration > 0 else 0
    
    print("\n" + "="*50)
    print("📈 REPORTE DE ESTRÉS SENTINEL")
    print("="*50)
    print(f"✅ Mensajes Exitosos: {stats['sent']}")
    print(f"❌ Mensajes Fallidos:  {stats['failed']}")
    print(f"⏱️  Duración Total:     {duration:.2f}s")
    print(f"🚀 Rendimiento (Tps):  {throughput:.2f} msg/s")
    print(f"🕒 Latencia Promedio:  {avg_latency:.4f}s")
    print("="*50)

if __name__ == "__main__":
    run_stress_test()
