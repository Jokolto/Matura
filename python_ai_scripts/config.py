import logging



class ServerConfig:
    HOST = "localhost"
    PORT = 9000
    BUFFER_SIZE = 2048

    # Q-learning constants
    LEARNING_RATE = 0.1
    DISCOUNT_FACTOR = 0.9
    EPSILON = 0.1


class RewardConfig:
    REWARDS = {    # not constant btw
        "TOOK_DAMAGE": -1.0,
        "TIME_ALIVE": 0.05,
        "HIT_PLAYER": 15.0,
        "RETREATED": -2.0,
        "WASTED_MOVEMENT": -1.0,
        "MOVED_CLOSER": 1.0,
        "MISSED": 0,
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