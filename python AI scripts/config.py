# config.py


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
    DAMAGE_TAKEN = -10.0
    BULLET_DODGE = 2.0
    TIME_ALIVE = 0.05
    HIT_PLAYER = 5.0


