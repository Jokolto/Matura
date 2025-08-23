# ai_server.gd
extends Node

class_name AIServer

var agents = {}          # enemy_id (String): QLearner
var fitnesses = {}       # enemy_id (String): float
var shared_brain         # SharedQLearner
var running = true

func _init():
	shared_brain = QLearner.SharedQLearner.new()

func handle_message(msg: Dictionary) -> Dictionary:
	var msg_type = msg.get("type", "")
	var data = msg.get("data", {})

	match msg_type:
		"STATE":
			return handle_state_msg(data)
		"REWARD":
			handle_reward_msg(data)
		"FITNESS":
			handle_fitness_msg(data)
		"WAVE_END":
			handle_wave_end()
		_:
			Logger.log("Unknown message type: %s" % msg_type, "DEBUG")

	return {} # default empty response

func handle_state_msg(data: Dictionary) -> Dictionary:
	var msg = {
		"type": "ACTION",
		"data": {}
	}

	for enemy_id in data.keys():
		var enemy_info = data[enemy_id]
		var state = enemy_info["state"]
		var valid_actions = enemy_info["valid_actions"]

		var agent = get_or_create_agent(str(enemy_id))
		var action = agent.choose_action(state, valid_actions)

		msg["data"][str(enemy_id)] = action

	Logger.log("Chosen actions for enemies: %s" % msg["data"], "DEBUG")
	return msg


func handle_reward_msg(data: Dictionary) -> void:
	for enemy_id_str in data.keys():
		var agent = get_or_create_agent(enemy_id_str)
		var events = data[enemy_id_str]

		for event in events:
			var event_type = event["event_type"]
			var new_state = event["new_state"]
			var action_to_reward = event["action_to_reward"]
			var state_to_reward = event["state_to_reward"]

			var reward = GlobalConfig.REWARDS.get(event_type)
			if reward == null:
				Logger.log("Unknown event type %s for enemy %s" % [event_type, enemy_id_str], "DEBUG")
			else:
				agent.apply_reward(reward, new_state, action_to_reward, state_to_reward)


func handle_fitness_msg(data: Dictionary) -> void:
	for enemy_id_str in data.keys():
		fitnesses[enemy_id_str] = data[enemy_id_str]
	Logger.log("Resulting fitnesses: %s " % fitnesses, "DEBUG")
	handle_wave_end()


func handle_wave_end() -> void:
	shared_brain.q_table.clear()

	var learners = []
	for agent in agents.values():
		var fitness = fitnesses.get(int(agent.enemy_id), 0.0)
		learners.append([agent, fitness])

	shared_brain.average_all(learners)

	Logger.log("Shared brain updated. Q-table: %s" % shared_brain.q_table, "DEBUG")

	agents.clear()
	fitnesses.clear()


func get_or_create_agent(enemy_id: String):
	if not agents.has(enemy_id):
		var agent = shared_brain.duplicate(true)
		agent.enemy_id = enemy_id
		agents[enemy_id] = agent
	return agents[enemy_id]
