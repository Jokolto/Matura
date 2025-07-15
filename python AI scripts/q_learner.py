import random

class QLearner:
    def __init__(self, enemy_id=None, last_action=None, last_state=None, learning_rate=0.1, discount_factor=0.95):
        self.q_table = {}
        self.enemy_id = enemy_id
        self.last_action = last_action
        self.last_state = last_state
        self.learning_rate = learning_rate
        self.discount_factor = discount_factor


    def get_q_value(self, state: str, action: str) -> float:
        if state not in self.q_table:
            self.q_table[state] = {}
        if action not in self.q_table[state]:
            self.q_table[state][action] = 0.0
        return self.q_table[state][action]

    def apply_reward(self, reward, new_state):
        if self.last_state is None or self.last_action is None:
            return

        old_value = self.get_q_value(self.last_state, self.last_action)

        # Get max future Q value
        if new_state in self.q_table and self.q_table[new_state]:
            max_future_q = max(self.q_table[new_state].values())
        else:
            max_future_q = 0.0

        # Update Q-value using the Q-learning formula
        new_value = old_value + self.learning_rate * (reward + self.discount_factor * max_future_q - old_value)
        self.q_table[self.last_state][self.last_action] = new_value

    def choose_action(self, state: str, valid_actions: list[str], epsilon: float = 0.1) -> str:
        self.last_state = state

        # Epsilon-greedy action selection
        if random.random() < epsilon:
            action = random.choice(valid_actions)

        # If state is not in Q-table or has no actions, choose a random action
        elif state not in self.q_table or not self.q_table[state]:
            action = random.choice(valid_actions)
        else:
            action = max(self.q_table[state], key=self.q_table[state].get)
        
        self.last_action = action
        return action

       


class SharedQLearner(QLearner):
    def __init__(self):
        super().__init__(enemy_id="shared")

    def merge_from(self, other, weight=1.0):
        for state, actions in other.q_table.items():
            if state not in self.q_table:
                self.q_table[state] = {}

            for action, q in actions.items():
                if action not in self.q_table[state]:
                    self.q_table[state][action] = 0.0

                self.q_table[state][action] += q * weight

    def average_all(self, learners_with_fitness):
        total_fitness = sum(f for _, f in learners_with_fitness)
        if total_fitness == 0:
            return  # Avoid div-by-zero

        self.q_table = {}  # Reset shared brain

        for learner, fitness in learners_with_fitness:
            self.merge_from(learner, weight=(fitness / total_fitness))