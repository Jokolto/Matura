extends Node2D

var next_enemy_id = 0
var next_state_id = 0
var last_snapshot: int = 0 # sec


func _ready() -> void:
	EntitiesManager.wave_end.connect(_on_wave_end)

func _process(_delta: float) -> void:
	if len(get_alive_enemies()) == 0:
		return
	
	# data collection
	if GlobalConfig.EXPERIMENTING and last_snapshot < EntitiesManager.wave_timer_discrete:
		last_snapshot = EntitiesManager.wave_timer_discrete
		AiClient.send_message_to_server(create_wave_snapshot_msg())
	
	
	# 1. Gather states for all enemies
	var states_msg = create_states_msg(get_all_states())
	
	# 2. Send states to Python server (non-blocking)
	var response_or_error = AiClient.send_message_to_server(states_msg)   # actions if no python server, otherwise error code
	var actions: Dictionary = Dictionary()
	if GlobalConfig.USE_PYTHON_SERVER:
		# 3. Process incoming messages (actions, logs, init) server should send actions after getting states
		AiClient.process_incoming_bytes()
		AiClient.handle_pending_messages()
		
		# 4. Pull latest actions dictionary
		actions = AiClient.get_latest_actions()
		Logger.log("Got actions from server: %s" % [actions], "DEBUG")
	else:
		# or 4. get action directly from message
		actions = response_or_error['data']
	
	# 5. Execute actions for all enemies
	process_actions(actions)
	
	 # 6. Collect events and send rewards
	var events = get_all_events()
	Logger.log("Sending reward events to server: %s" % [events], "DEBUG")
	send_reward_requests_for_events(events)
	

func get_next_enemy_id() -> int:
	var id = next_enemy_id
	next_enemy_id += 1
	return id


func get_alive_enemies():
	var alive = []
	for enemy: Enemy in get_children():
		if not enemy.is_dead:
			alive.append(enemy)
	return alive


func get_all_states() -> Dictionary:
	var state_bundle = {}
	for enemy: Enemy in get_alive_enemies():
		state_bundle[enemy.enemy_id] = {
			"state": enemy.get_state(),
			"valid_actions": enemy.valid_actions,
			"enemy_type": enemy.enemy_type
		}
	return state_bundle


func get_all_events() -> Dictionary:
	var event_bundle = {}
	for enemy: Enemy in get_alive_enemies():
		var events = enemy.get_unsent_events()
		if len(events) != 0:
			event_bundle[enemy.enemy_id] = events
	return event_bundle

func get_death_log(enemy: Enemy) -> Dictionary:
	return {
		"run_id": GlobalConfig.run_id,
		"seed": GlobalConfig.seed_n,
		"config": GlobalConfig.config,
		"wave": EntitiesManager.current_wave,
		"time": EntitiesManager.wave_timer,  # seconds since wave start
		"log_type": "death",
		"enemy_id": enemy.enemy_id,
		"damage": enemy.damage_dealt,
		"lifespan": enemy.life_time_sec,
		"fitness": enemy.fitness,
		#"mutations_applied": enemy.mut_count, 
		#"parent_ids": enemy.parent_ids 
	}

# Collect aggregate snapshot (e.g., called every second)
func get_wave_snapshot_log() -> Dictionary:
	var enemies: Array = get_alive_enemies()
	var n_alive = enemies.size()
	var mean_fit = 0.0
	if n_alive > 0:
		for enemy: Enemy in enemies:
			enemy.calculate_fitness()
			mean_fit += enemy.fitness
		mean_fit /= n_alive

	return {
		"run_id": GlobalConfig.run_id,
		"seed": GlobalConfig.seed_n,
		"config": GlobalConfig.config,
		"wave": EntitiesManager.current_wave,
		"time": EntitiesManager.wave_timer_discrete,
		"log_type": "wave_snapshot",
		"mean_fitness_alive": mean_fit,
		"n_alive": n_alive
	}

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
	next_state_id += 1
	return {
		"type": "STATE",
		"data": payload, 
		"state_id": next_state_id
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

func create_death_log_msg(enemy: Enemy) -> Dictionary:
	return {
		"type": "LOG",
		"data": get_death_log(enemy)
	}

func create_wave_snapshot_msg() -> Dictionary:
	return {
		"type": "LOG",
		"data": get_wave_snapshot_log()
	}

func get_enemy_by_id(id: int) -> Enemy:
	for enemy: Enemy in get_alive_enemies():
		if enemy.enemy_id == id:
			return enemy
	return null


func process_actions(actions):
	for enemy: Enemy in get_alive_enemies():
		var action = actions.get(str(enemy.enemy_id), "idle")
		enemy.last_action = action
		enemy.execute_action(action)

# best function ever
func kill_all():
	for enemy: Enemy in get_alive_enemies():
		enemy.take_damage(99999)

func get_distance_and_angle_to_closest_enemy_from(entity) -> Array:
	var min_distance = INF
	var closest: Enemy = null
	for other_enemy in get_alive_enemies():
		if other_enemy and other_enemy != entity:
			var dist = entity.global_position.distance_to(other_enemy.global_position)
			if dist < min_distance:
				min_distance = dist
				closest = other_enemy
			
	if closest:
		var to_ally = (closest.global_position - entity.global_position).normalized()
		var angle = entity.move_dir.angle_to(to_ally)  # in radians
		return [min_distance, angle, closest]
	
	return [min_distance, -1.0, null]

func _on_wave_end(fitness_per_enemy):
	var fitness_msg = create_fitness_msg(fitness_per_enemy)
	AiClient.send_message_to_server(fitness_msg)
	Logger.log("Sent fitness data to server: %s" % [fitness_msg], "DEBUG")
	last_snapshot = 0


func _on_enemy_death(enemy: Enemy):
	if GlobalConfig.EXPERIMENTING:
		var msg = create_death_log_msg(enemy)
		AiClient.send_message_to_server(msg)
