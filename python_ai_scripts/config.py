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
    # Define rewards for different actions
    TOOK_DAMAGE = -1.0
    TIME_ALIVE = 0.05
    HIT_PLAYER = 15.0
    RETREATED = -2.0  # Penalty for retreating
    WASTED_MOVEMENT = -1.0  # Penalty for wasted movement
    MOVED_CLOSER = 1.0  # Reward for moving closer to the player
    MISSED = 0  # Penalty for missing an attack

    @classmethod
    def get(cls, name: str):
        return getattr(cls, name, None)


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