# Ported from python using chatitigpt so it can be uploaded to itch.io easier
extends Resource

class_name QLearner

const MAX_PENDING = 100

var q_table = {}
var enemy_id: String
var enemy_type: GlobalConfig.EnemyTypes
var pending_actions: Array = []   # queue of (state, action)
var discount_factor = GlobalConfig.DISCOUNT_FACTOR
var learning_rate = GlobalConfig.LEARNING_RATE

func _init(new_enemy_id: String = ""):
	enemy_id = new_enemy_id

func get_q_value(state: String, action: String) -> float:
	if not q_table.has(state):
		q_table[state] = {}
	if not q_table[state].has(action):
		q_table[state][action] = 0.0
	return q_table[state][action]

func apply_reward(reward: float, new_state: String, action_to_reward: String, state_to_reward: String) -> void:
	var state: String
	var action: String

	if action_to_reward == null and state_to_reward == null:
		if pending_actions.is_empty():
			Logger.log("No pending actions to apply reward to.", "DEBUG")
			return
		var pair = pending_actions.pop_front()
		state = pair[0]
		action = pair[1]
	else:
		state = state_to_reward
		action = action_to_reward

	var old_value = get_q_value(state, action)

	var max_future_q = 0.0
	if q_table.has(new_state) and q_table[new_state].size() > 0:
		max_future_q = get_max_value(q_table[new_state].values())

	var new_value = old_value + learning_rate * (reward + discount_factor * max_future_q - old_value)
	q_table[state][action] = new_value

func choose_action(state: String, valid_actions: Array, epsilon: float = 0.1) -> String:
	var action
	# Explore
	if randf() < epsilon or not q_table.has(state) or q_table[state].size() == 0:
		action = valid_actions[randi() % valid_actions.size()]
	else:
		var best_action = ""
		var best_value = -INF
		for a in q_table[state].keys():
			if q_table[state][a] > best_value:
				best_value = q_table[state][a]
				best_action = a
		action = best_action

	# Store for later reward
	pending_actions.append([state, action])
	if pending_actions.size() > MAX_PENDING:
		pending_actions.pop_front()

	return action

func _to_string() -> String:
	return "QLearner(enemy_id=%s)" % enemy_id


class SharedQLearner:
	extends QLearner
 	
	# type specifies between which type of enemies the q table is shared, e.g MeleeEnemy or RangedEnemy
	func _init(type: GlobalConfig.EnemyTypes=GlobalConfig.EnemyTypes.Generic):
		super._init("sharedtype %s" % [type])
		enemy_type = type

	# Previous crossover strategy	
	func merge_from(other: QLearner, weight: float = 1.0) -> void:
		for state in other.q_table.keys():
			if not q_table.has(state):
				q_table[state] = {}
			for action in other.q_table[state].keys():
				if not q_table[state].has(action):
					q_table[state][action] = 0.0
				q_table[state][action] += other.q_table[state][action] * weight
	
	
	func average_all(learners_with_fitness: Array) -> void:
		var total_fitness = 0.0
		for pair in learners_with_fitness:
			total_fitness += pair[1]  # (learner, fitness)

		if total_fitness == 0.0:
			Logger.log("No fitness data to average, skipping merge.", "INFO")
			return

		for pair in learners_with_fitness:
			var learner: QLearner = pair[0]
			var fitness: float = pair[1]
			merge_from(learner, fitness / total_fitness)


# gdscript max does not allow to pass arrays to check max values, crazy shit
func get_max_value(array: Array) -> float:
	var m = -INF
	for v in array:
		if v > m:
			m = v
	return m
