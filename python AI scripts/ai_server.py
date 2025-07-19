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


class AIServer:
    def __init__(self):
        self.agents = {}  # enemy_id -> QLearner
        self.fitnesses = {}  # enemy_id -> float
        self.shared_brain = SharedQLearner()
        self.running = True

    def handle_client(self, conn, addr):
        with conn:
            logging.info(f"[Connection] Accepted connection from {addr}")
            buffer = ""
            while True:
                data = conn.recv(ServerConfig.BUFFER_SIZE)
                if not data:
                    logging.info(f"[Connection] Client {addr} disconnected.")
                    break
                try:
                    buffer += data.decode("utf-8")
                    while "\n" in buffer:
                        line, buffer = buffer.split("\n", 1)
                        if line.strip() == "":
                            continue
                        message = json.loads(line)
                        self.handle_message(message, conn)
                except json.JSONDecodeError as e:
                    logging.error(f"JSON decode error: {e} while processing data {repr(data.decode('utf-8'))}")
                    continue
    
    def handle_message(self, msg, conn):
        msg_type = msg.get("type")
        data = msg.get("data")

        if msg_type == "STATE":
            self.handle_state_msg(data, conn)
        elif msg_type == "REWARD":
            self.handle_reward_msg(data)
        else:
            logging.debug(f"Unknown message type: {msg_type}")
            

    def handle_state_msg(self, data, conn):
        msg = {
                "type": "ACTION",
                "data": {}}
                   
        for enemy_id, enemy_info in data.items():
            state = enemy_info["state"]
            valid_actions = enemy_info["valid_actions"]


            agent = self.get_or_create_agent(enemy_id)

            # Choose action based on current state and valid actions
            action = agent.choose_action(state, valid_actions)

            msg["data"][str(enemy_id)] = action

        logging.debug(f"Chosen actions for enemies: {msg['data']}")
        # Send the action back to the client  
        message = json.dumps(msg) + "\n"
        conn.sendall(message.encode("utf-8"))


    def handle_reward_msg(self, data):
        for enemy_id_str, events in data.items():
            enemy_id = int(enemy_id_str)
            agent = self.get_or_create_agent(enemy_id)

            for event in events:
                event_type = event["event_type"]
                new_state = event["new_state"]
                action_to_reward = event["action_to_reward"]

                # Pop the oldest action if you're queueing
                # state, action = agent.pending_actions.popleft()


                reward = REWARD_MAP.get(event_type, None)
                if reward is None:
                    logging.warning(f"Unknown event type '{event_type}' for enemy {enemy_id}, no reward applied.")
                else:
                    logging.debug(f"Applying reward {reward} of event {event_type} for action {action_to_reward} to agent {enemy_id}.")
                    agent.apply_reward(reward, new_state)
    
    def get_or_create_agent(self, enemy_id):
        if enemy_id not in self.agents:
            agent = QLearner(enemy_id=enemy_id)
            self.agents[enemy_id] = agent
        return self.agents[enemy_id]
    

                        # buffer += data.decode("utf-8")
                # while "\n" in buffer:
                #     line, buffer = buffer.split("\n", 1)
                #     if line.strip() == "":
                #         continue
                #     try:
                #         message = json.loads(line)
                #         msg_type = message.get("type", "UNKNOWN")
                #         enemy_id = message.get("enemy_id", "UNKNOWN")
                #         content = message.get("data", {})

                #         if enemy_id not in self.agents:
                #             # agent = copy.deepcopy(self.shared_brain)
                #             agent = QLearner(enemy_id=enemy_id)
                #             agent.enemy_id = enemy_id
                #             self.agents[enemy_id] = agent

                #         agent = self.agents[enemy_id]

                #         if msg_type == "STATE":
                #             state = content["state"]
                #             logging.debug(f"New state received from enemy {enemy_id}: {state}")
                #             valid_actions = content["valid_actions"]
                #             action = agent.choose_action(
                #                 state, valid_actions, ServerConfig.EPSILON
                #             )
                #             message = json.dumps({
                #                 "type": "ACTION",
                #                 "enemy_id": enemy_id,
                #                 "data": {"action": action}
                #             }) + "\n"
                #             conn.sendall(message.encode())
                #             logging.debug(f"Action chosen for enemy {enemy_id}: {action}")

                #         elif msg_type == "REWARD":
                #             event_type = content["event_type"]
                #             # logging.debug(f"New event received from enemy {enemy_id}: {event_type}")
                #             reward = REWARD_MAP.get(event_type, None)
                #             new_state = content["new_state"]
                #             if reward is None:
                #                 logging.warning(f"Unknown event type '{event_type}' for enemy {enemy_id}, no reward applied.")
                #             else:
                #                 agent.apply_reward(
                #                     reward,
                #                     new_state
                #                 )
                #                 logging.debug(f"Reward applied for enemy {enemy_id} for event {event_type}: {reward}. Pending Actions: {agent.pending_actions}")

                #         elif msg_type == "FITNESS":
                #             fitness = content["fitness"]
                #             self.fitnesses[enemy_id] = fitness

                #         elif msg_type == "WAVE_END":
                #             learners = [(agent, self.fitnesses.get(agent.enemy_id, 0.0)) for agent in self.agents.values()]
                #             self.shared_brain.average_all(learners)
                #             self.agents.clear()
                #             self.fitnesses.clear()
                #             logging.debug(f"Shared brain updated from wave.")

                #     except json.JSONDecodeError as e:
                #         print("JSON error:", e, "In message:", repr(line))

    def run(self):
        self.running = True
        logging.info("[Python AI Server] Starting server...")
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind((ServerConfig.HOST, ServerConfig.PORT))
            s.listen()
            logging.info(f"[Python AI Server] Server listening on {ServerConfig.HOST}:{ServerConfig.PORT}")
            while self.running:
                conn, addr = s.accept()
                self.handle_client(conn, addr)
                # threading.Thread(target=self.handle_client, args=(conn, addr)).start()

    def shutdown(self, signal_num, frame):
        logging.info("[SERVER] Shutting down server...")
        self.running = False
        sys.exit(0)


if __name__ == "__main__":
    server = AIServer()
    signal.signal(signal.SIGINT, server.shutdown)
    server.run()
