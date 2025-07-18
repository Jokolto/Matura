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
    "RETREATED": RewardConfig.RETREATED,
    "WASTED_MOVEMENT": RewardConfig.WASTED_MOVEMENT,
    "MOVED_CLOSER": RewardConfig.MOVED_CLOSER
}


logging.basicConfig(
    level=logging.DEBUG,
    format="[%(asctime)s] [%(levelname)s] [%(threadName)s] %(message)s",
    datefmt="%H:%M:%S",
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
        buffer = ""
        while True:
            data = conn.recv(ServerConfig.BUFFER_SIZE)
            if not data:
                break  # Client closed

            buffer += data.decode("utf-8")

            # Try splitting full messages
            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                if line.strip() == "":
                    continue

                try:
                    message = json.loads(line)
                    
                    msg_type = message.get("type", "UNKNOWN")
                    enemy_id = message.get("enemy_id", "UNKNOWN")
                    content = message.get("data", {})
                


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

                        message = json.dumps({
                            "type": "ACTION",
                            "enemy_id": enemy_id,
                            "data": { "action": action }
                        }) + "\n"   # Ensure newline at end of message to separate messages on client side
                        conn.sendall(message.encode())

                        logging.debug(f"Action chosen for enemy {enemy_id}: {action}")
                    
                    elif msg_type == "REWARD":
                        event_type = content["event_type"] 
                        logging.debug(f"New event received from enemy {enemy_id}: {event_type}")
                        reward = REWARD_MAP.get(event_type, None)
                        new_state = content["new_state"]  
                        if reward is None:
                            logging.warning(f"Unknown event type '{event_type}' for enemy {enemy_id}, no reward applied.")
                        else:
                            agent.apply_reward(
                                reward, 
                                new_state
                            )
                            logging.debug(f"Reward applied for enemy {enemy_id} for event {event_type}: {reward}. Pending Actions: {agent.pending_actions}")

                    elif msg_type == "FITNESS":
                        fitness = content["fitness"]
                        fitnesses[enemy_id] = fitness

                    elif msg_type == "WAVE_END":
                        learners = [(agent, fitnesses.get(agent.enemy_id, 0.0)) for agent in agents.values()]
                        shared_brain.average_all(learners)
                        agents.clear()
                        fitnesses.clear()
                        logging.debug(f"Shared brain updated from wave.")

                        
                except json.JSONDecodeError as e:
                    print("JSON error:", e, "In message:", repr(line))
    



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
