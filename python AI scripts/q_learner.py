import random
from collections import deque

MAX_PENDING = 100

class QLearner:
    def __init__(self, enemy_id=None, learning_rate=0.1, discount_factor=0.95):
        self.q_table = {}
        self.enemy_id = enemy_id
        self.learning_rate = learning_rate
        self.discount_factor = discount_factor
        self.last_state = ""
        self.last_action = ""
        self.pending_actions = deque()  # queue of (state, action)


    def get_q_value(self, state: str, action: str) -> float:
        if state not in self.q_table:
            self.q_table[state] = {}
        if action not in self.q_table[state]:
            self.q_table[state][action] = 0.0
        return self.q_table[state][action]

    def apply_reward(self, reward, new_state):
        
        if not self.pending_actions:
            print("No pending actions to apply reward to.", self.pending_actions)
            return  # Nothing to apply reward to

        # state, action = self.last_state, self.last_action
        state, action = self.pending_actions.popleft()
        old_value = self.get_q_value(state, action)
        
        # Calculate max future Q-value for the new state
        if new_state in self.q_table and self.q_table[new_state]:
            max_future_q = max(self.q_table[new_state].values())
        else:
            max_future_q = 0.0

        new_value = old_value + self.learning_rate * (reward + self.discount_factor * max_future_q - old_value) # Update Q-value according to Q-learning formula
        
        self.q_table[state][action] = new_value

    def choose_action(self, state: str, valid_actions: list[str], epsilon: float = 0.1) -> str:
        self.last_state = state

         # Explore if epsilon hits or state is unknown
        if random.random() < epsilon or state not in self.q_table or not self.q_table[state]:
            action = random.choice(valid_actions)
        else:
            action = max(self.q_table[state], key=self.q_table[state].get)
        
        self.last_action = action
        # Store for later reward
        self.pending_actions.append((state, action))
        
        if len(self.pending_actions) > MAX_PENDING:
            self.pending_actions.popleft()
        print(self.pending_actions)
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