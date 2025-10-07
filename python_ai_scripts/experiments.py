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
    output_csv: str = '',
    seed: int = 0
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
        '--output_csv', str(output_csv),
        "--seed", str(seed)
    ]
    
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
        "--audio-driver", "Dummy",
        "--",
        f"--run_id={run_id}",
        f"--seed={seed}",
        f"--config={config}",
        f"--port={port}",
        f"--waves={waves_amount}",
    ]
    return subprocess.Popen(cmd)

# main experiment method. some leak errors after each godot is exited are expected, i solved some of them but due to time not all of them, they are harmless anyway.
def run_experiments():
    output_csv_base = r'C:\projects\matura\python_ai_scripts\data'
    repeats = 5
    until_wave = 15  

    configs = [ "base", "q_only",  "ga_only", "gen_q_learning"]
    # what each config does. Config effects work only if EXPERIMENTING in godot is true:
    # base - enemies have random q values without rewards. Implemented in godot with no_q_learning parameter and in python with condition of config
    # q_only - enemies learn intra wave, but not with each wave. Implemented in python server with not filling shared q table
    # ga_only - enemies have random q values without rewards, but best are selected at wave end to be reproduced in next with some mutation. uses no_q_learning parameter in godot and in python with condition of config
    # gen_q_learning - uses both algorithms, default in release.

    port_base = 9000

    for run_id, cfg in enumerate(configs, start=1):
        seed = random.randint(0, 999999)
        # seed = 1
        port = port_base + run_id # in case i decide to run in parallel

        print(f"\n=== Starting experiment {run_id} ({cfg}) ===")
        
        output_csv = os.path.join(output_csv_base, str(cfg), f'run_{run_id}.csv')
        # output_csv = ''   # to not record experiment result leave it empty or not pass at all

        logger = start_logger(port, run_id=run_id, config_name=cfg, output_csv=output_csv, seed=seed)
        godot = run_godot(run_id, seed, cfg, port, waves_amount=until_wave)

        # Wait for Godot to finish
        godot.wait()
        logger.terminate()

        time.sleep(0.2)

    print("\nAll experiments finished!")

if __name__ == "__main__":
    run_experiments()
    
