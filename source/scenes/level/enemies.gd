extends Node

var next_enemy_id = 0
var tick = 0

func _ready() -> void:
	EntitiesManager.wave_end.connect(_on_wave_end)

func _process(_delta: float) -> void:
	if len(get_enemies()) == 0:
		return
	
	var states_msg = create_states_msg(get_all_states())
	var actions = get_actions_from_server(states_msg)
	Logger.log("Got actions from server: %s" % [actions], "DEBUG")
	process_actions(actions)
	var events = get_all_events()
	Logger.log("Sending reward events to server: %s" % [events], "DEBUG")
	send_reward_requests_for_events(events)
	

func get_next_enemy_id() -> int:
	var id = next_enemy_id
	next_enemy_id += 1
	return id


func get_enemies():
	return get_children()


func get_all_states() -> Dictionary:
	var state_bundle = {}
	for enemy: Enemy in get_enemies():
		state_bundle[enemy.enemy_id] = {
			"state": enemy.get_state(),
			"valid_actions": enemy.valid_actions
		}
	return state_bundle


func get_all_events() -> Dictionary:
	var event_bundle = {}
	for enemy: Enemy in get_enemies():
		var events = enemy.get_unsent_events()
		if len(events) != 0:
			event_bundle[enemy.enemy_id] = events
	return event_bundle


func send_states_to_server(states: Dictionary) -> void:
	var msg = create_states_msg(states)
	AiClient.send_json_from_dict_message(msg)

func get_actions_from_server(states) -> Dictionary:
	var response = AiClient.get_ai_actions(states)
	return response

func send_reward_requests_for_events(events: Dictionary) -> void:
	if events.size() == 0:
		return
	var msg = create_event_msg(events)
	#Logger.log("Sent reward to Server: %s" % [msg], "DEBUG")
	AiClient.send_message_to_server(msg)


func create_states_msg(states_bundle: Dictionary) -> Dictionary:
	var payload = {}
	for enemy_id in states_bundle.keys():
		payload[enemy_id] = states_bundle[enemy_id]
	return {
		"type": "STATE",
		"data": payload
	}


func create_event_msg(event_bundle: Dictionary) -> Dictionary:
	var reward_data = {}
	for enemy_id in event_bundle.keys():
		reward_data[str(enemy_id)] = []
		for ev in event_bundle[enemy_id]:
			reward_data[str(enemy_id)].append({
				"event_type": ev['event_type'],
				"state_to_reward": ev["state_to_reward"],
				"action_to_reward": ev["action_to_reward"],
				"new_state": ev['new_state']
			})
	return {
		"type": "REWARD",
		"data": reward_data
	}
	
func create_fitness_msg(fitness_per_enemy: Dictionary) -> Dictionary:
	return {
		"type": "FITNESS",
		"data": fitness_per_enemy
	}

func get_enemy_by_id(id: int) -> Enemy:
	for enemy: Enemy in get_enemies():
		if enemy.enemy_id == id:
			return enemy
	return null


func process_actions(data_with_actions):
	var data = data_with_actions.get("data", {})
	for enemy: Enemy in get_enemies():
		var action = data.get(str(enemy.enemy_id), "idle")
		enemy.last_action = action
		enemy.execute_action(action)

# best function ever
func kill_all():
	for enemy: Enemy in get_enemies():
		enemy.take_damage(99999)

func _on_wave_end(fitness_per_enemy):
	var fitness_msg = create_fitness_msg(fitness_per_enemy)
	AiClient.send_message_to_server(fitness_msg)
	Logger.log("Sent fitness data to server: %s" % [fitness_msg], "DEBUG")
