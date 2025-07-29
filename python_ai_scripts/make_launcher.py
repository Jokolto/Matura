import subprocess
import time
import os
import signal

# Start server (Python script or exe)
server_process = subprocess.Popen(["ai_server.exe"])  # or ["python", "server.py"]

# Wait a moment for server to initialize
time.sleep(1)

# Start the game
game_process = subprocess.Popen(["buildtest.exe"])

# Wait for the game to close
game_process.wait()

# Terminate the server
server_process.terminate()  # Graceful shutdown
# Or force-kill:
# server_process.kill()