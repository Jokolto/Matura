import socket
import json
import threading
import copy
import signal
import sys


from q_learner import QLearner, SharedQLearner
from config import ServerConfig, RewardConfig, Logger


Logger.init()
logging = Logger.get_logger(__name__) 


class AIServer:
    def __init__(self):
        self.agents = {}  # enemy_id (str): QLearner
        self.fitnesses = {}  # enemy_id (str) : float
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

        match msg_type:
            case "STATE":
                self.handle_state_msg(data, conn)
            case "REWARD":
                self.handle_reward_msg(data)
            case "FITNESS":
                self.handle_fitness_msg(data)
            case "WAVE_END":
                self.handle_wave_end()
            case "SHUTDOWN":
                self.shutdown(signal.SIGINT, None)
            case _:
                logging.debug(f"Unknown message type: {msg_type}")
                

    def handle_state_msg(self, data, conn):
        msg = {
                "type": "ACTION",
                "data": {}}
                   
        for enemy_id, enemy_info in data.items():
            state = enemy_info["state"]
            valid_actions = enemy_info["valid_actions"]


            agent = self.get_or_create_agent(str(enemy_id))

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
            agent = self.get_or_create_agent(enemy_id_str)

            for event in events:
                event_type = event["event_type"]
                new_state = event["new_state"]
                action_to_reward = event["action_to_reward"]

                # Pop the oldest action if you're queueing
                # state, action = agent.pending_actions.popleft()


                reward = RewardConfig.get(event_type)
                
                if reward is None:
                    logging.warning(f"Unknown event type '{event_type}' for enemy {enemy_id}, no reward applied.")
                else:
                    logging.debug(f"Applying reward {reward} of event {event_type} for action {action_to_reward} to agent {enemy_id}.")
                    agent.apply_reward(reward, new_state)
    
    def handle_wave_end(self):
        self.shared_brain.q_table = {}  # Reset shared brain
        # Merge all agents' Q-tables into the shared brain
        learners = [(agent, self.fitnesses.get(agent.enemy_id, 0.0)) for agent in self.agents.values()]
        logging.debug(f"Merging {learners} into shared brain.")
        self.shared_brain.average_all(learners)
        logging.debug(f"Shared brain updated from wave. Resulting Shared Q-table: {self.shared_brain.q_table}")
        
        # Clear agents and fitnesses for the next wave
        self.agents.clear()
        self.fitnesses.clear()

    def handle_fitness_msg(self, data):
        # Update fitnesses for each agent
        for enemy_id_str, fitness in data.items():
            self.fitnesses[enemy_id_str] = fitness
        logging.debug(f"Resulting fitnesses: {self.fitnesses}")
        self.handle_wave_end()  # Process the end of the wave after receiving fitness data
        


    def get_or_create_agent(self, enemy_id: str):
        if enemy_id not in self.agents:
            agent = copy.deepcopy(self.shared_brain)
            agent.enemy_id = enemy_id
            self.agents[enemy_id] = agent
        return self.agents[enemy_id]
    

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
