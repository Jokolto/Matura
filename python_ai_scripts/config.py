import logging



class ServerConfig:
    HOST = "localhost"
    PORT = 9000
    BUFFER_SIZE = 2048

    # Q-learning constants
    LEARNING_RATE = 0.2
    DISCOUNT_FACTOR = 0.9
    EPSILON = 0.2


class RewardConfig:
    REWARDS = {    
        "TOOK_DAMAGE": -2.0,
        "TIME_ALIVE": 0.05,
        "HIT_PLAYER": 14.0,
        "RETREATED": -0.2,
        "WASTED_MOVEMENT": -0.1,
        "MOVED_CLOSER": 0.05,
        "MISSED": -0.2,
        "DIED": -7,
        "STUCK": -5
    }

    @classmethod
    def get(cls, name: str):
        return cls.REWARDS.get(name, None)

    @classmethod
    def update_rewards(cls, new_rewards: dict):
        cls.REWARDS.update(new_rewards)


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