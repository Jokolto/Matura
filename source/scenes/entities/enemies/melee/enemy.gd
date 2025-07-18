class_name Enemy extends CharacterBody2D

@export var stats: Resource = preload("res://resources/enemies/general_enemy.tres")


@onready var body_sprite = $AnimatedSprite2D


var player: CharacterBody2D = null  # assigned from spawner
var projectiles_node: Node = null # assigned from spawner

var move_speed: float 
var max_health: float 
var health: float
var contact_damage: float

var player_inside_contact_range: bool = false
var enemy_id: int = -1


## State parameters
var life_time_sec: float = 0
var dodged_bullets: Array = []
var dodged_bullet: bool = false
var bullet_nearby_dist: float = 150
var player_nearby_dist: float = 400
var bullet_threat_timer := 0.0
var dodge_reward_threshold_sec = 0.7
var is_in_danger = false

### Batch sizes
var dist_batch_size = null

var valid_actions = ["move_forward", "strafe_left", "strafe_right", "retreat"]


signal enemy_death()

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	#enemy_death.connect(_on_death)
	enemy_death.connect(EntitiesManager._on_enemy_death)
	enemy_death.connect(GameManager.hud._on_enemy_death)
	generate_id()
	
	move_speed = stats.move_speed
	max_health = stats.max_health 
	contact_damage = stats.contact_damage
	health = max_health
	


func _physics_process(delta: float) -> void:
	if not player:
		return
	
	# Sending data to server
	var state: String = get_state() # returns something like "d20a90bd0ba0"
	var state_msg: Dictionary = create_state_msg(enemy_id, state) 
	
	# Receiving data from server
	var action_msg: Dictionary = AiClient.get_ai_action(state_msg)
	var msg_to_enemy_id = action_msg.get("enemy_id", -1)
	var msg_type = action_msg.get("type", "")
	var msg_data = action_msg.get("data", {})
	if msg_type == "ACTION":
		if msg_to_enemy_id == enemy_id:
			var action: String = msg_data.get("action")  
			Logger.log("Enemy %s executing action %s " % [enemy_id, action], "DEBUG")
			execute_action(action, delta)
	
	# Attacking
	if player_inside_contact_range:
		_deal_damage(player)
		#apply_reward(hiting_player_reward)

func _process(delta: float) -> void:
	life_time_sec += delta
	if is_in_danger:
		bullet_threat_timer += delta
		if bullet_threat_timer >= dodge_reward_threshold_sec:
			apply_reward(GlobalConfig.RewardEvents["DODGED_BULLET"])  # Survived close to a bullet for 1 second
	#apply_reward(GlobalConfig.RewardEvents["TIME_ALIVE"])
		

func create_state_msg(id, state) -> Dictionary:
	return {
		"type": "STATE",
		"enemy_id": id,
		"data": {
			"valid_actions": valid_actions,
			"state": state
			}
		}

func create_event_msg(id: int, event_type: String, new_state: String) -> Dictionary:
	return {
		"type": "REWARD",
		"enemy_id": id,
		"data": {
			"event_type": event_type,
			"new_state": new_state
			}
		}


func set_player(player_instance):
	player = player_instance


func set_projectiles_node(node: Node):
	projectiles_node = node

func take_damage(amount: float) -> void:
	if health <= 0:   # multiple bullets could kill enemies multiple times without this
		return 
		
	health -= amount
	apply_reward(GlobalConfig.RewardEvents["TOOK_DAMAGE"])
	if health <= 0:
		enemy_death.emit()
		queue_free()
		

func execute_action(action: String, _delta: float):
	var dir = (player.global_position - global_position).normalized()
	match action:
		"move_forward":
			velocity = dir * move_speed
			apply_reward(GlobalConfig.RewardEvents["MOVED_CLOSER"])
		"retreat":
			velocity = -dir * move_speed
			apply_reward(GlobalConfig.RewardEvents["RETREATED"])
		"strafe_left":
			velocity = dir.rotated(-PI/2) * move_speed
			apply_reward(GlobalConfig.RewardEvents["WASTED_MOVEMENT"])
		"strafe_right":
			velocity = dir.rotated(PI/2) * move_speed
			apply_reward(GlobalConfig.RewardEvents["WASTED_MOVEMENT"])
		_:
			velocity = Vector2.ZERO
	move_and_slide()

func get_state() -> String:
	
	#var pos_x = floor(global_position.x / 50.0)
	#var pos_y = floor(global_position.y / 50.0)
	var dist = floor(global_position.distance_to(player.global_position) / 100.0)
	var angle = floor(global_position.angle_to_point(player.global_position) / (PI / 4))
	
	var nearest_bullet = projectiles_node.get_nearest_player_bullet_to_pos(global_position)
	var bullet_dist = 5
	var bullet_angle = 0
	if nearest_bullet:
		bullet_dist = floor(global_position.distance_to(nearest_bullet.global_position) / 50.0)
		bullet_angle = floor(global_position.angle_to_point(nearest_bullet.global_position) / (PI / 4))
		if (not (nearest_bullet.name in dodged_bullets)) and (global_position.distance_to(nearest_bullet.global_position) <= bullet_nearby_dist):
			is_in_danger = true
			
			if bullet_threat_timer >= dodge_reward_threshold_sec:
				dodged_bullets.append(nearest_bullet.name)
				bullet_threat_timer = 0.0
				is_in_danger = false
		else:
			# Not in danger
			is_in_danger = false
			bullet_threat_timer = 0.0
	
	bullet_dist = clamp(dist, 0, 4)
	bullet_angle = clamp(angle, 0, 7)			
	dist = clamp(dist, 0, 4)
	angle = clamp(angle, 0, 7)
	return "d{d}a{a}bd{bd}ba{ba}".format({"d": dist, "a":angle, "bd": bullet_dist, "ba": bullet_angle})


func apply_reward(event_type: String):
	var new_state = get_state()
	var reward_msg = create_event_msg(enemy_id, event_type, new_state)
	Logger.log("Sending the reward request of enemy %s to server of event: %s" % [enemy_id, event_type], "DEBUG")
	AiClient.send_json_from_dict_message(reward_msg)

## End AI

func generate_id():
	if enemy_id == -1:
		enemy_id = EntitiesManager.get_next_enemy_id()

	# Generate a name like "Goblin_3" or "Orc_5"
	var type_name = get_name()
	name = "%s_%d" % [type_name, enemy_id]
	

func _update_animation(input_vec: Vector2) -> void:
	# ---- play the correct clip ----
	if input_vec != Vector2.ZERO:
		if body_sprite.animation != "run":
			body_sprite.play("run")
	else:
		if body_sprite.animation != "idle":
			body_sprite.play("idle")
	 #---- face the correct direction ----  // no need, gun aim decides the orientation
	if input_vec.x != 0:
		body_sprite.flip_h = input_vec.x < 0
		

func _deal_damage(body: Node) -> void:
	body.take_damage(contact_damage)
	


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_inside_contact_range = true
		
		
func _on_body_exited(body: Node) -> void:
	if body is Player:	
		player_inside_contact_range = false
		
		

#func _on_death():
	#queue_free()
