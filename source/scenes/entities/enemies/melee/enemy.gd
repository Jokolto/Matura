class_name Enemy extends CharacterBody2D

@export var stats: Resource = preload("res://resources/enemies/general_enemy.tres")


@onready var body_sprite = $AnimatedSprite2D


var player: CharacterBody2D = null  # assigned from spawner
var projectiles_node: Node = null # assigned from spawner
var enemies_node: Node = null # assigned from spawner

var move_speed: float 
var max_health: float 
var health: float
var contact_damage: float

var player_inside_contact_range: bool = false
var enemy_id: int = -1


## State parameters
var current_state = ""


var dodged_bullets: Array = []
var dodged_bullet: bool = false
var bullet_nearby_dist: float = 150
var player_nearby_dist: float = 400
var bullet_threat_timer := 0.0
var dodge_reward_threshold_sec = 0.7
var is_in_danger = false

# for fitness calculation
var fitness: float = 0.0
var life_time_sec: float = 0
var damage_dealt: float = 0
var min_dist_to_player: float = INF

var fitness_damage_priority_formula = func(life_time, dmg_dealt, min_distance): 
	return dmg_dealt * 2.0 + life_time * 0.5 - min_distance * 0.1

var fitness_survivability_priority = func(life_time, dmg_dealt, min_distance): 
	return life_time * 2.0 + dmg_dealt * 0.5 - min_distance * 0.1


### Batch sizes
var dist_batch_size = 1000 
var valid_actions = ["move_forward", "strafe_left", "strafe_right", "retreat"]
var last_action = ""
var event_buffer := []

signal enemy_death(enemy)

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
	

func _process(delta: float) -> void:
	if not player:
		return
	
	if velocity > Vector2.ZERO:
		body_sprite.play("run")
	
	current_state = get_state() # returns something like "d20a90bd0ba0"
	
	# Attacking
	if player_inside_contact_range:
		_deal_damage(player)
		#apply_reward(hiting_player_reward)
	life_time_sec += delta
	#if is_in_danger:
		#bullet_threat_timer += delta
		#if bullet_threat_timer >= dodge_reward_threshold_sec:
			#add_reward_event(GlobalConfig.RewardEvents["DODGED_BULLET"])  # Survived close to a bullet for 1 second
	#add_reward_event(GlobalConfig.RewardEvents["TIME_ALIVE"])
		

func set_player(player_instance):
	player = player_instance


func set_projectiles_node(node: Node):
	projectiles_node = node

func take_damage(amount: float) -> void:
	if health <= 0:   # multiple bullets could kill enemies multiple times without this
		return 
		
	health -= amount
	add_reward_event(GlobalConfig.RewardEvents["TOOK_DAMAGE"])
	if health <= 0:
		fitness = fitness_damage_priority_formula.call(life_time_sec, damage_dealt, min_dist_to_player)
		enemy_death.emit(self)
		queue_free()
		

func execute_action(action: String):
	var dir = (player.global_position - global_position).normalized()
	match action:
		"move_forward":
			velocity = dir * move_speed
			add_reward_event(GlobalConfig.RewardEvents["MOVED_CLOSER"])
		"retreat":
			velocity = -dir * move_speed
			add_reward_event(GlobalConfig.RewardEvents["RETREATED"])
		"strafe_left":
			velocity = dir.rotated(-PI/2) * move_speed
			add_reward_event(GlobalConfig.RewardEvents["WASTED_MOVEMENT"])
		"strafe_right":
			velocity = dir.rotated(PI/2) * move_speed
			add_reward_event(GlobalConfig.RewardEvents["WASTED_MOVEMENT"])
		_:
			velocity = Vector2.ZERO
	move_and_slide()

func get_state() -> String:
	#var pos_x = floor(global_position.x / 50.0)
	#var pos_y = floor(global_position.y / 50.0)
	var dist_not_batch = global_position.distance_to(player.global_position)
	if min_dist_to_player > dist_not_batch:
		min_dist_to_player = dist_not_batch
	var dist = floor(dist_not_batch / 200.0)
	var angle = floor(global_position.angle_to_point(player.global_position) / (PI / 2))
	
	var nearest_bullet = projectiles_node.get_nearest_player_bullet_to_pos(global_position)
	var bullet_dist = 5
	var bullet_angle = 0
	if nearest_bullet:
		bullet_dist = floor(global_position.distance_to(nearest_bullet.global_position) / 200.0)
		bullet_angle = floor(global_position.angle_to_point(nearest_bullet.global_position) / (PI / 2))
		#if (not (nearest_bullet.name in dodged_bullets)) and (global_position.distance_to(nearest_bullet.global_position) <= bullet_nearby_dist):
			#is_in_danger = true
			#
			#if bullet_threat_timer >= dodge_reward_threshold_sec:
				#dodged_bullets.append(nearest_bullet.name)
				#bullet_threat_timer = 0.0
				#is_in_danger = false
		#else:
			## Not in danger
			#is_in_danger = false
			#bullet_threat_timer = 0.0
	
	bullet_dist = clamp(dist, 0, 4)
	bullet_angle = clamp(angle, 0, 4)			
	dist = clamp(dist, 0, 4)
	angle = clamp(angle, 0, 4)
	return "d{d}a{a}bd{bd}ba{ba}".format({"d": dist, "a":angle, "bd": bullet_dist, "ba": bullet_angle})

func get_events():
	var unset = get_unsent_events()
	cleanup_old_events()
	return unset


func add_reward_event(event_type: String) -> void:
	event_buffer.append({
		"event_type": event_type,
		"state_to_reward": current_state,
		"action_to_reward": last_action,
		"new_state": get_state(),
		"sent": false
	})


func get_unsent_events() -> Array:
	var unsent = []
	for event in event_buffer:
		if not event["sent"]:
			unsent.append(event)
			event["sent"] = true  # Mark it
	return unsent

func cleanup_old_events():
	# Optional: call this every few seconds
	event_buffer = event_buffer.filter(func(ev): return not ev["sent"] or is_still_relevant(ev))

func is_still_relevant(_event):
	return false

## End AI

func generate_id():
	if enemy_id == -1:
		enemy_id = enemies_node.get_next_enemy_id()

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
	damage_dealt += contact_damage
	


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_inside_contact_range = true
		
		
func _on_body_exited(body: Node) -> void:
	if body is Player:	
		player_inside_contact_range = false
		
		
func set_enemies_node(node: Node):
	enemies_node = node
