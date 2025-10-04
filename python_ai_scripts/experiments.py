import subprocess
import time
import random
import os

# === CONFIG === 
PROJECT_PATH = r"C:/projects/matura/source/"  
SERVER_PATH = r'C:\projects\matura\python_ai_scripts\ai_server.py'
GODOT_PATH = "godot" # works cause i have registered godot in path

# === HELPER FUNCTIONS ===

def start_logger(port, run_id):
    """Start Python server, it will write CSV."""
    return subprocess.Popen(
        ["python", SERVER_PATH, str(port), str(run_id)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

def run_godot(run_id, seed, config, port):
    """Launch Godot instance headlessly."""
    cmd = [
        GODOT_PATH,   
        # "--headless",
        "--path", PROJECT_PATH,
        "--",
        f"--run_id={run_id}",
        f"--seed={seed}",
        f"--config={config}",
        f"--port={port}",
    ]
    print(f"[RUN {run_id}] Starting Godot...")
    return subprocess.Popen(cmd)

# === MAIN EXPERIMENT RUN ===
def run_experiments():
    configs = ["q_only", "q_genetic"]   # whatever configs you want
    port_base = 50007

    for i, cfg in enumerate(configs, start=1):
        seed = random.randint(0, 999999)
        port = port_base + i

        print(f"\n=== Starting experiment {i} ({cfg}) ===")

        logger = start_logger(port, i)
        godot = run_godot(i, seed, cfg, port)

        # Wait for Godot to finish
        godot.wait()
        print(f"[RUN {i}] Godot finished. Shutting down logger...")
        logger.terminate()

        time.sleep(2)

    print("\nAll experiments finished!")

if __name__ == "__main__":
    run_experiments()
