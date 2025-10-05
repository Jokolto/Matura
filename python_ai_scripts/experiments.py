import subprocess
import time
import random
import os
import sys

# config
PROJECT_PATH = r'C:\projects\matura\source' 
SERVER_PATH = r'C:\projects\matura\python_ai_scripts\ai_server.py'
GODOT_PATH = "godot" # works cause i have registered godot in path


def start_logger(
    port: int,
    run_id: int = 0,
    config_name: str = "q_only",
    learning_rate: float = 0.2,
    discount_factor: float = 0.9,
    epsilon: float = 0.2,
    output_csv: str | None = None
):
    """Start the Python server that logs experiment data."""
    cmd = [
        sys.executable,
        SERVER_PATH,
        "--port", str(port),
        "--run_id", str(run_id),
        "--config", config_name,
        "--learning_rate", str(learning_rate),
        "--discount_factor", str(discount_factor),
        "--epsilon", str(epsilon),
    ]

    if output_csv:
        cmd += ["--output_csv", output_csv]
    
    proc = subprocess.Popen(
        cmd,
        # stdout=subprocess.PIPE,  # runs without output of the server,
        # stderr=subprocess.PIPE
    )
    return proc

def run_godot(run_id, seed, config, port, waves_amount):
    """Launch Godot instance headlessly."""
    cmd = [
        GODOT_PATH,   
        "--headless",
        "--path", PROJECT_PATH,
        "--",
        f"--run_id={run_id}",
        f"--seed={seed}",
        f"--config={config}",
        f"--port={port}",
        f"--waves={waves_amount}",
    ]
    return subprocess.Popen(cmd)

# main experiment method
def run_experiments():
    output_csv_base = r'C:\projects\matura\python_ai_scripts\data'
    repeats = 5
    until_wave = 1  
    configs = ["q_only", "ga_only", "gen_q_learning"]
    port_base = 9000

    for run_id, cfg in enumerate(configs, start=1):
        seed = random.randint(0, 999999)
        port = port_base + run_id

        print(f"\n=== Starting experiment {run_id} ({cfg}) ===")
        
        output_csv = os.path.join(output_csv_base, str(cfg), f'run_{run_id}.csv')
        logger = start_logger(port, run_id=run_id, config_name=cfg, output_csv=output_csv)
        godot = run_godot(run_id, seed, cfg, port, waves_amount=until_wave)

        # Wait for Godot to finish
        godot.wait()
        logger.terminate()

        time.sleep(0.2)

    print("\nAll experiments finished!")

if __name__ == "__main__":
    run_experiments()
    
