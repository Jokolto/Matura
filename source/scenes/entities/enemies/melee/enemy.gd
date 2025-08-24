class_name Enemy extends CharacterBody2D

@export var stats: Resource = preload("res://resources/enemies/general_enemy.tres")

@onready var body_sprite = $AnimatedSprite2D

# assigned from spawner
var player: CharacterBody2D = null  
var projectiles_node: Node2D = null
var enemies_node: Node2D = null 
var pickup_node: Node2D = null 
var hud: CanvasLayer = null 
var ui: Node = null

var move_speed: float 
var max_health: float 
var health: float
var contact_damage: float
var dir: Vector2 = Vector2.RIGHT

var player_inside_contact_range: bool = false
var enemy_id: int = -1


var weapon_instance: Weapon = null
var weapon_res: Resource = null
var weapon_drop_chance: float = 0.2 # 20 percent

var current_state = ""
var last_action = ""
var event_buffer := []

# for fitness calculation
var fitness: float = 0.0
var life_time_sec: float = 0
var damage_dealt: float = 0
var min_dist_to_player: float = INF

var fitness_damage_priority_formula = func(life_time, dmg_dealt, min_distance): 
	return dmg_dealt * 2.0 + life_time * 0.1 - min_distance * 0.005

var fitness_survivability_priority = func(life_time, dmg_dealt, min_distance): 
	return life_time * 1.0 + dmg_dealt * 0.5 - min_distance * 0.001


### Batch sizes
var dist_batch_size = GlobalConfig.GameConfig["Y_MAP_SIZE"] # take the lower
var valid_actions = ["move_forward", "strafe_left", "strafe_right", "retreat", "use_weapon"]



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
		if player.contact_damage:
			take_damage(player.contact_damage)
		add_reward_event(GlobalConfig.RewardEvents["HIT_PLAYER"])
	life_time_sec += delta


func set_player(player_instance):
	player = player_instance

func set_ui(node):
	ui = node

func set_projectiles_node(node: Node):
	projectiles_node = node

func take_damage(amount: float) -> void:
	if health <= 0:   # multiple bullets could kill enemies multiple times without this
		return 
		
	health -= amount
	ui.show_damage_ui(amount, global_position)
	add_reward_event(GlobalConfig.RewardEvents["TOOK_DAMAGE"])
	if health <= 0:
		fitness = fitness_damage_priority_formula.call(life_time_sec, damage_dealt, min_dist_to_player)
		enemy_death.emit(self)
		if weapon_instance and pickup_node and randf() <= weapon_drop_chance:
			call_deferred('drop_current_weapon')   # gives some bs warning without call deferred
		queue_free()
		



func execute_action(action: String):
	dir = (player.global_position - global_position).normalized()
	var shooting_dir = player.global_position
	last_action = action
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
		"use_weapon":
			if weapon_instance and weapon_instance.is_ready():
				weapon_instance.use_weapon(shooting_dir)
				weapon_instance.store_state(current_state, action)
			# gets its reward from bullet if it hits player
		_:
			velocity = Vector2.ZERO
	move_and_slide()

# a lot of magical numbers, that were found by trial and error
func get_state() -> String:
	#var pos_x = floor(global_position.x / 50.0)
	#var pos_y = floor(global_position.y / 50.0)
	var dist_not_batch = global_position.distance_to(player.global_position)
	if min_dist_to_player > dist_not_batch:
		min_dist_to_player = dist_not_batch
	var dist = floor(dist_not_batch / 200.0)   # 400 is aproximately 1/5 of the map
	var angle = round(global_position.angle_to_point(player.global_position) / (PI / 2)) # 4 possible angles, divided by quadrants
	
	var dist_and_angle_to_ally = get_distance_and_angle_to_closest_ally()
	var dist_ally = floor(dist_and_angle_to_ally[0] / 200)
	var angle_ally = (dist_and_angle_to_ally[1] / 200)
	
	var nearest_bullet = projectiles_node.get_nearest_player_bullet_to_pos(global_position)
	var bullet_dist = -1  # no bullets flying
	var bullet_angle = -1  # no bullets flying
	if nearest_bullet:
		bullet_dist = floor(global_position.distance_to(nearest_bullet.global_position) / 100.0) # Here short distance is quite important, therefore 200 which is 1/10 of map
		bullet_angle = round(global_position.angle_to_point(nearest_bullet.global_position) / (PI / 2))
	bullet_dist = clamp(dist, 0, 1)   # clamp makes only 5 parameters possible for the state, you could think of it as 0 - close, 1 - medium... distances. anything bigger than 4 is 4, so long dist
	bullet_angle = clamp(angle, 0, 3)			
	dist = clamp(dist, 0, 2)
	angle = clamp(angle, 0, 3)
	dist_ally = clamp(dist_ally, 0, 2)
	angle_ally = clamp(angle_ally, 0, 3)
	var weapon_type = -1   # no weapon means -1 in state
	if weapon_instance:
		weapon_type = weapon_instance.weapon_type  # distinguish between melee and ranged
	return "wt{wt}d{d}a{a}bd{bd}ba{ba}ad{ad}".format({
		"wt": weapon_type, "d": dist, "a":angle, "bd": bullet_dist, "ba": bullet_angle, "ad": dist_ally, "aa": angle_ally
		})

func get_events():
	var unset = get_unsent_events()
	cleanup_old_events()
	return unset


func add_reward_event(event_type: String, state_to_reward = current_state, action_to_reward = last_action) -> void:
	event_buffer.append({
		"event_type": event_type,
		"state_to_reward": state_to_reward,
		"action_to_reward": action_to_reward,
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
	event_buffer = event_buffer.filter(func(ev): return not ev["sent"] or is_still_relevant(ev))

func is_still_relevant(_event):
	return false

func get_distance_and_angle_to_closest_ally() -> Array:
	var min_distance = INF
	var closest: Enemy = null
	for other_enemy in enemies_node.get_enemies():
		if other_enemy and other_enemy != self:
			var dist = global_position.distance_to(other_enemy.global_position)
			if dist < min_distance:
				min_distance = dist
				closest = other_enemy
			
	if closest:
		var to_ally = (closest.global_position - global_position).normalized()
		var angle = dir.angle_to(to_ally)  # in radians
		return [min_distance, angle]
	
	return [min_distance, -1.0]

func generate_id():
	if enemy_id == -1:
		enemy_id = enemies_node.get_next_enemy_id()

	# Generate a name like "Goblin_3" or "Orc_5"
	var type_name = get_name()
	name = "%s_%d" % [type_name, enemy_id]
	

func _update_animation(input_vec: Vector2) -> void:
	if input_vec != Vector2.ZERO:
		if body_sprite.animation != "run":
			body_sprite.play("run")
	else:
		if body_sprite.animation != "idle":
			body_sprite.play("idle")
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

func set_pickup_node(pickup_n):
	pickup_node = pickup_n

func drop_current_weapon():
	var drop = weapon_instance
	drop.get_parent().remove_child(drop)
	pickup_node.add_child(drop)
	drop.global_position = global_position + Vector2.RIGHT.rotated(rotation) * 16
	drop.enter_pickup_state()
	
