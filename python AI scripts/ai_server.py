import socket
import json
import threading
import copy
import logging
import signal
import sys


from q_learner import QLearner, SharedQLearner  

# === CONFIG ===
from config import ServerConfig, RewardConfig 


LOG_FILENAME = "ai_server.log"
REWARD_MAP = {
    "TOOK_DAMAGE": RewardConfig.DAMAGE_TAKEN,
    "DODGED_BULLET": RewardConfig.BULLET_DODGE,
    "HIT_PLAYER": RewardConfig.HIT_PLAYER,
    "TIME_ALIVE": RewardConfig.TIME_ALIVE,
}

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] [%(threadName)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILENAME, mode='w'),
        logging.StreamHandler()
    ]
)

agents = {}  # enemy_id -> QLearner
fitnesses = {}  # enemy_id -> float
shared_brain = SharedQLearner()
running = True

def handle_client(conn, addr):
    with conn:
        logging.info(f"[Connection] Accepted connection from {addr}")
        while True:
            try:
                data = conn.recv(ServerConfig.BUFFER_SIZE)
                if not data:
                    break
                try:
                    message = json.loads(data.decode())
                except Exception as e:
                    logging.warning("[Error] Got Bad JSON:", e)
                    continue

                msg_type = message.get("type")
                enemy_id = message.get("enemy_id")
                content = message.get("data")

                if enemy_id not in agents:
                    # Start with clone of shared brain
                    agent = copy.deepcopy(shared_brain)
                    agent.enemy_id = enemy_id
                    agents[enemy_id] = agent

                agent = agents[enemy_id]

                if msg_type == "STATE":
                    state = content["state"]
                    logging.debug(f"New state received from enemy {enemy_id}: {state}")
                    valid_actions = content["valid_actions"]
                    action = agent.choose_action(
                        state, valid_actions, ServerConfig.EPSILON
                    )

                    conn.sendall(json.dumps({
                        "type": "ACTION",
                        "enemy_id": enemy_id,
                        "data": { "action": action }
                    }).encode())

                    logging.debug(f"Action chosen for enemy {enemy_id}: {action}")
                
                elif msg_type == "REWARD":
                    event_type = content["event_type"]
                    logging.debug(f"New event received from enemy {enemy_id}: {event_type}")
                    reward = REWARD_MAP.get(event_type, 0.0)
                    new_state = content["new_state"]
                    agent.apply_reward(
                        reward, new_state,
                        ServerConfig.LEARNING_RATE,
                        ServerConfig.DISCOUNT_FACTOR
                    )
                    logging.debug(f"Reward applied for enemy {enemy_id} for event {event_type}: {reward}")

                elif msg_type == "FITNESS":
                    fitness = content["fitness"]
                    fitnesses[enemy_id] = fitness

                elif msg_type == "WAVE_END":
                    learners = [(agent, fitnesses.get(agent.enemy_id, 0.0)) for agent in agents.values()]
                    shared_brain.average_all(learners)
                    agents.clear()
                    fitnesses.clear()
                    logging.debug(f"Shared brain updated from wave.")
                

            except Exception as e:
                logging.warning(f"Exception from {addr}: {e}")
                break

def run_server():
    running = True
    logging.info("[Python AI Server] Starting server...")
    # Create a socket and bind it to the host and port
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((ServerConfig.HOST, ServerConfig.PORT))
        s.listen()
        logging.info(f"[Python AI Server] Server listening on {ServerConfig.HOST}:{ServerConfig.PORT}")
        while running:
            conn, addr = s.accept()
            threading.Thread(target=handle_client, args=(conn, addr)).start()


def shutdown_server(signal_num, frame):
    print("[SERVER] Shutting down server...")
    running = False  # Your server loop should respect this flag
    sys.exit(0)


if __name__ == "__main__":
    # Attach signal handler
    signal.signal(signal.SIGINT, shutdown_server)

    # Start the server
    run_server()
