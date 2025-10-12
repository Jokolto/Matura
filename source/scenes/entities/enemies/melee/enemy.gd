class_name Enemy extends CharacterBody2D

@export var stats: Resource = preload("res://resources/enemies/general_enemy.tres")

@onready var body_sprite = $AnimatedSprite2D
@onready var contact_damage_area = $Area2D
@onready var hitbox = $CollisionShape2D
@onready var contact_damage_hitbox = $Area2D/CollisionShape2D

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
var move_dir: Vector2 = Vector2.RIGHT

var player_inside_contact_range: bool = false
var dodged_this_frame: bool = false
var is_dead: bool = false
var enemy_id: int
var enemy_type: GlobalConfig.EnemyTypes = GlobalConfig.EnemyTypes.Generic # would change after equiping weapon

# Knockback variables
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay := 800.0

# Weapon variables. It is expanded in ranged enemy subclass.
var weapon_instance: Weapon = null
var weapon_res: Resource = null
var weapon_drop_chance: float = 0.2 # 20 percent

# for state calculation
var current_state = ""
var last_action = ""
var event_buffer := []
var last_dist_to_player: float = INF
var last_bullet: Bullet = null
var last_dist_to_bullet: float = INF

# for fitness calculation
var fitness: float = 0.0
var life_time_sec: float = 0
var damage_dealt: float = 0
var dodged_bullets: int = 0
var min_dist_to_player: float = INF

var fitness_damage_priority_formula = func(life_time, dmg_dealt, dodged_b, _min_distance): # earlier it used min distance as negative paramater
	return dmg_dealt * 7.0 + life_time * 0.2 + 1 * dodged_b

var fitness_survivability_priority = func(life_time, dmg_dealt, dodged_b, _min_distance): 
	return life_time * 1.0 + dmg_dealt * 0.5 + 5 * dodged_b


### Batch sizes
var dist_batch_size = GlobalConfig.GameConfig["Y_MAP_SIZE"] # take the lower
var valid_actions = ["move_forward", "strafe_left", "strafe_right", "retreat", "use_weapon"]

var relative_sector: int = -1

signal enemy_death(enemy)

func _ready() -> void:
	contact_damage_area.body_entered.connect(_on_body_entered)
	contact_damage_area.body_exited.connect(_on_body_exited)
	#enemy_death.connect(_on_death)
	enemy_death.connect(EntitiesManager._on_enemy_death)
	enemy_death.connect(GameManager.hud._on_enemy_death)
	enemy_death.connect(enemies_node._on_enemy_death)
	generate_id()
	
	move_speed = stats.move_speed
	max_health = stats.max_health 
	contact_damage = stats.contact_damage
	health = max_health
	

func _process(delta: float) -> void:
	if not player or is_dead:
		return

	life_time_sec += delta
	if velocity > Vector2.ZERO:
		body_sprite.play("run")
	
	if weapon_instance and weapon_instance.is_ready():
		valid_actions.append("use_weapon")
	else:
		if valid_actions.has("use_weapon"):
			valid_actions.remove_at(valid_actions.find("use_weapon"))
	
	current_state = get_state() # returns something like "d20a90bd0ba0"
	# Attacking with contact damage
	if player_inside_contact_range and contact_damage > 0:
		_deal_damage(player)
		if player.contact_damage:
			take_damage(player.contact_damage)
		add_reward_event(GlobalConfig.RewardEvents["HIT_PLAYER"])
	
	
	if dodged_this_frame:
		add_reward_event(GlobalConfig.RewardEvents["DODGED_BULLET"])
		dodged_this_frame = false
		
	


func set_player(player_instance):
	player = player_instance

func set_ui(node):
	ui = node

func set_projectiles_node(node: Node):
	projectiles_node = node

func take_damage(amount: float) -> void:
	if is_dead:
		return 
	
	dodged_this_frame = false
	health -= amount
	ui.show_damage_ui(amount, global_position)
	add_reward_event(GlobalConfig.RewardEvents["TOOK_DAMAGE"])
	if health <= 0:
		die()
		

func die():
	if is_dead:
		return
	is_dead = true
	body_sprite.play("death")
	calculate_fitness()
	enemy_death.emit(self)
	add_reward_event(GlobalConfig.RewardEvents["DIED"])
	if weapon_instance and pickup_node and randf() <= weapon_drop_chance:
		call_deferred('drop_current_weapon')   # gives some bs warning without call deferred
	elif weapon_instance:
		weapon_instance.queue_free()
	
	hitbox.set_deferred('disabled', true)
	contact_damage_hitbox.set_deferred('disabled', true)
	
	# Create tween animation for death
	var tween = create_tween()
	tween.set_parallel()  
	
	# Fly upwards a bit
	tween.tween_property(self, "position:y", position.y - 30, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Turn gray
	tween.tween_property(body_sprite, "modulate", Color(0.3, 0.3, 0.3, 0.8), 0.1)
	
	var angle = deg_to_rad(70)  # 70° tilt
	if move_dir.x < 0:
		# Player is left, rotate clockwise, go right
		tween.tween_property(self, "rotation", angle, 0.3)
		tween.tween_property(self, "position:x", position.x + 30, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		# Player is right, rotate counter-clockwise, go left
		tween.tween_property(self, "rotation", -angle, 0.8)
		tween.tween_property(self, "position:x", position.x - 30, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.finished.connect(queue_free)

func calculate_fitness():
	fitness = fitness_damage_priority_formula.call(life_time_sec, damage_dealt, dodged_bullets, min_dist_to_player)


func execute_action(action: String):
	move_dir = (player.global_position - global_position).normalized()
	var shooting_move_dir = player.global_position

	var ai_velocity := Vector2.ZERO

	match action:
		"move_forward":
			ai_velocity = move_dir * move_speed
			add_reward_event(GlobalConfig.RewardEvents["MOVED_CLOSER"])
		"retreat":
			ai_velocity = -move_dir * move_speed
			add_reward_event(GlobalConfig.RewardEvents["RETREATED"])
		"strafe_left":
			ai_velocity = move_dir.rotated(-PI/2) * move_speed
			add_reward_event(GlobalConfig.RewardEvents["WASTED_MOVEMENT"])
		"strafe_right":
			ai_velocity = move_dir.rotated(PI/2) * move_speed
			add_reward_event(GlobalConfig.RewardEvents["WASTED_MOVEMENT"])
		"use_weapon":
			if weapon_instance and weapon_instance.is_ready():
				weapon_instance.use_weapon(shooting_move_dir)
				weapon_instance.store_state(current_state, action)
		_:
			ai_velocity = Vector2.ZERO

	# Combine AI movement + knockback
	velocity = ai_velocity + knockback_velocity
	move_and_slide()

	# Decay knockback over time
	if knockback_velocity.length() > 0.1:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * get_process_delta_time())

	last_action = action
	var current_dist_to_player = global_position.distance_to(player.global_position)
	if last_action == "move_forward" and current_dist_to_player == last_dist_to_player:
		add_reward_event(GlobalConfig.RewardEvents["STUCK"])

# a lot of magical numbers, that were found by trial and error
func get_state() -> String:
	var pos_x = floor(global_position.x / 500.0)
	var pos_y = floor(global_position.y / 500.0)
	var dist_not_batch = global_position.distance_to(player.global_position)
	last_dist_to_player = dist_not_batch
	if min_dist_to_player > dist_not_batch:
		min_dist_to_player = dist_not_batch
	var dist = floor(dist_not_batch / 500.0)   # 400 is aproximately 1/5 of the map
	var angle = round(global_position.angle_to_point(player.global_position) / (PI / 2)) # 4 possible angles, divided by quadrants
	
	var dist_and_angle_to_ally = enemies_node.get_distance_and_angle_to_closest_enemy_from(self) # also closest enemy instance at index 2
	var dist_ally = floor(dist_and_angle_to_ally[0] / 400)
	var angle_ally = (dist_and_angle_to_ally[1] / 400)
	
	var relative_move_dir = get_relative_sector(global_position, player.global_position, player.aim_vector)
	var nearest_bullet = projectiles_node.get_nearest_player_bullet_to_pos(global_position) as Bullet
	var bullet_dist = 2 
	var bullet_angle = -1  # no bullets flying
	if is_instance_valid(nearest_bullet):
		bullet_dist = floor(global_position.distance_to(nearest_bullet.global_position) / 50.0) # Here short distance is quite important, therefore 200 which is 1/10 of map
		bullet_angle = round(global_position.angle_to_point(nearest_bullet.global_position) / (PI / 2))
		bullet_dist = clamp(bullet_dist, 0, 2)  
		bullet_angle = clamp(bullet_angle, -1, 3)
		if is_instance_valid(last_bullet) and last_bullet.is_inside_tree() and nearest_bullet.bullet_id == last_bullet.bullet_id:
			var dodge_condition = bullet_dist > last_dist_to_bullet and last_dist_to_bullet == 0
			if dodge_condition and not nearest_bullet.dodged: # and not ... might be unnecessary, it also makes that bullet can be dodged only by one enemy
				dodged_bullets += 1
				dodged_this_frame = true
				nearest_bullet.dodged = true
		
		last_dist_to_bullet = bullet_dist
		nearest_bullet.last_dist_to_enemy = bullet_dist
		last_bullet = nearest_bullet
	
	 # clamp makes only 5 parameters possible for the state, you could think of it as 0 - close, 1 - medium... distances. anything bigger than 4 is 4, so long dist
	dist = clamp(dist, 0, 2)
	angle = clamp(angle, 0, 3)
	dist_ally = clamp(dist_ally, -1, 2)
	angle_ally = clamp(angle_ally, -1, 3)
	
	var weapon_type = -1   # no weapon means -1 in state
	if is_instance_valid(weapon_instance):
		weapon_type = weapon_instance.weapon_type  # distinguish between melee and ranged
	var player_weapon_type = -1
	if is_instance_valid(player.weapon_instance):
		player_weapon_type = player.weapon_instance.weapon_type
	# unused: px{px}py{py}
	return "wt{wt}pw{pw}d{d}a{a}bd{bd}ba{ba}ad{ad}".format({
		"wt": weapon_type, "pw": player_weapon_type, 
		#"px": pos_x, "py": pos_y,
		"d": dist, "a": relative_move_dir, 
		"bd": bullet_dist, "ba": bullet_angle, 
		#"ad": dist_ally, "aa": angle_ally 
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


# returns relative angle to player, with also accounting to player aim
func get_relative_sector(enemy_pos: Vector2, player_pos: Vector2, aim_vector: Vector2, sectors: int = 8) -> int:
	if aim_vector == Vector2.ZERO:
		return -1
	var to_enemy = (enemy_pos - player_pos).normalized()
	var aim_angle = aim_vector.angle()
	var relative_angle = wrapf(to_enemy.angle() - aim_angle, -PI, PI)
	var sector_size = TAU / sectors
	return int(floor((relative_angle + sector_size/2) / sector_size)) % sectors

func generate_id():
	if enemy_id == 0:
		enemy_id = enemies_node.get_next_enemy_id()

	# Generate a name like "Goblin_3" or "Orc_5"
	var type_name = get_name()
	name = "%s_%d" % [type_name, enemy_id]
	

func _update_animation(input_vec: Vector2) -> void:
	if is_dead:
		body_sprite.play('death')
		return
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
	
