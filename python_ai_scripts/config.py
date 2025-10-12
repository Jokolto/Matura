import logging


# changed to be configurable with multiple instances possible for experiments
class ServerConfig:
    def __init__(
        self,
        host="localhost",
        port=9000,
        buffer_size=2048,
        learning_rate=0.1,
        discount_factor=0.9,
        epsilon=0.1,
        mutation_prob=0.05,
        mutation_range=0.1
    ):
        self.HOST = host
        self.PORT = port
        self.BUFFER_SIZE = buffer_size
        self.LEARNING_RATE = learning_rate
        self.DISCOUNT_FACTOR = discount_factor
        self.EPSILON = epsilon
        self.MUTATION_PROB = mutation_prob
        self.MUTATION_RANGE = mutation_range


# same thing, also no classmethods now.
class RewardConfig:
    def __init__(self, rewards=None):
        self.REWARDS = {
            "TOOK_DAMAGE": -5,
            "TIME_ALIVE": 0.0,
            "HIT_PLAYER": 10,
            "RETREATED": -0.2,
            "WASTED_MOVEMENT": -0.05,
            "MOVED_CLOSER": 0.05,
            "MISSED": -0.2,
            "DIED": -5,
            "STUCK": -1,
            "DODGED_BULLET": 6
        }
        if rewards:
            self.REWARDS.update(rewards)
            
    def get(self, name: str):
        return self.REWARDS.get(name, None)

    def update_rewards(self, new_rewards: dict):
        self.REWARDS.update(new_rewards)


class Logger:
    LOG_FILENAME = "ai_server.log"

    @staticmethod
    def init():
        logging.basicConfig(
            level=logging.INFO,
            format="[%(asctime)s] [%(levelname)s] [%(name)s] [%(threadName)s] %(message)s",
            datefmt="%H:%M:%S",
            handlers=[
                logging.FileHandler(Logger.LOG_FILENAME, mode='w'),
                logging.StreamHandler()
            ]
        )

    @staticmethod
    def get_logger(name: str) -> logging.Logger:
        return logging.getLogger(name)