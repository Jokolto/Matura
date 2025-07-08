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

# AI PARAMETERS
## Rewards
var hiting_player_reward: int = 5
var geting_hit_reward: int = -7
var dodging_reward: int = 6
var wasting_movement_reward: int = -1

## State parameters
var life_time_sec: float = 0
var dodged_bullets: int = 0
var player_shot_nearby: bool = 0
var player_nearby_dist: float = 400

## Constants
const LEARNING_RATE = 1
const DISCOUNT_FACTOR = 0.9
const EXPLORATION_RATE = 0.2
var last_state := ""
var last_action := ""
var brain = QTableApproach 
var q_table: Dictionary = {}

signal enemy_death(enemy)

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	#enemy_death.connect(_on_death)
	enemy_death.connect(EntitiesManager._on_enemy_death)
	enemy_death.connect(GameManager.hud._on_enemy_death)
	
	init_from_shared_brain(brain.shared_q_table)
	generate_id()
	
	move_speed = stats.move_speed
	max_health = stats.max_health 
	contact_damage = stats.contact_damage
	health = max_health
	
	


#func _physics_process(_delta: float) -> void:   ## Already smart behavior, not using Ai
	#var dir: Vector2 = Vector2.ZERO
	#if is_instance_valid(player):
		#dir = (player.global_position - global_position).normalized()
		#velocity = dir * move_speed
		#move_and_slide()
	#if player_inside_contact_range:
		#_deal_damage(player)
	#
	#_update_animation(dir)

func _physics_process(delta: float) -> void:
	if not player:
		return

	var state = get_state()
	var action = choose_action(state)
	last_state = state
	last_action = action

	execute_action(action, delta)
	
	if player_inside_contact_range:
		_deal_damage(player)
		apply_reward(5)

func _process(delta: float) -> void:
	life_time_sec += delta
	
	

func set_player(player_instance):
	player = player_instance


func set_projectiles_node(node: Node):
	projectiles_node = node

func take_damage(amount: float) -> void:
	if health <= 0:   # multiple bullets could kill enemies multiple times without this
		return 
		
	health -= amount
	apply_reward(geting_hit_reward)
	if health <= 0:
		enemy_death.emit(get_q_table())
		queue_free()
		
# Ai 
func choose_action(state: String) -> String:
	const ACTIONS = ["move_forward", "strafe_left", "strafe_right", "retreat", "shoot"]
	
	var best_action = ACTIONS[0]
	var best_value = -INF
	if randf() < EXPLORATION_RATE or !q_table.has(state):
		best_action = ACTIONS[randi() % ACTIONS.size()]
		return best_action


	for action in ACTIONS:
		var value = get_q_value(state, action)
		if value > best_value:
			best_value = value
			best_action = action
	
	#print(best_action)
	return best_action
	

func get_q_value(state: String, action: String) -> float:
	if !q_table.has(state):
		q_table[state] = {}
	if !q_table[state].has(action):
		q_table[state][action] = 0.0
	return q_table[state][action]
	
func update_q_value(state: String, action: String, reward: float, new_state: String) -> void:
	var old_value = get_q_value(state, action)
	var max_future_q = -INF

	if q_table.has(new_state):
		for next_action in q_table[new_state].keys():
			max_future_q = max(max_future_q, get_q_value(new_state, next_action))
	else:
		max_future_q = 0.0

	var new_value = old_value + LEARNING_RATE * (reward + DISCOUNT_FACTOR * max_future_q - old_value)
	q_table[state][action] = new_value

func execute_action(action: String, _delta: float):
	var dir = (player.global_position - global_position).normalized()
	match action:
		"move_forward":
			velocity = dir * move_speed
		"retreat":
			velocity = -dir * move_speed
			apply_reward(-3)
		"strafe_left":
			velocity = dir.rotated(-PI/2) * move_speed
			#apply_reward(-1)
		"strafe_right":
			velocity = dir.rotated(PI/2) * move_speed
			#apply_reward(-1)	
		_:
			velocity = Vector2.ZERO
	move_and_slide()

func get_state() -> String:
	#var pos_x = floor(global_position.x / 50.0)
	#var pos_y = floor(global_position.y / 50.0)
	var dist = floor(global_position.distance_to(player.global_position) / 50.0)
	var angle = floor(global_position.angle_to_point(player.global_position) / (PI / 4))
	
	var nearest_bullet = projectiles_node.get_nearest_player_bullet_to_pos(global_position)
	var bullet_dist = 5
	var bullet_angle = 0
	if nearest_bullet:
		bullet_dist = floor(global_position.distance_to(nearest_bullet.global_position) / 50.0)
		bullet_angle = floor(global_position.angle_to_point(nearest_bullet.global_position) / (PI / 4))

		
	dist = clamp(dist, 0, 4)
	angle = clamp(angle, 0, 7)
	return "d{d}a{a}bd{bd}ba{ba}".format({"d": dist, "a":angle, "bd": bullet_dist, "ba": bullet_angle})

func get_q_table() -> Dictionary:
	return q_table

func apply_reward(reward: float):
	var new_state = get_state()
	update_q_value(last_state, last_action, reward, new_state)

func init_from_shared_brain(shared_brain: Dictionary):
	q_table = {}  # Make a deep copy to keep independence
	for state in shared_brain.keys():
		q_table[state] = {}
		for action in shared_brain[state].keys():
			q_table[state][action] = shared_brain[state][action]
			
			
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
