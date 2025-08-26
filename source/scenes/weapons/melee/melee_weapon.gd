# melee_weapon.gd
class_name MeleeWeapon
extends Weapon

var is_attacking: bool = false
var current_angle: float = 0.0
var swing_direction: int = 1
var swing_speed: float
var damage: float

func _ready():
	super._ready()
	weapon_type = GlobalConfig.EnemyTypes.Melee
	
func _process(delta: float) -> void:
	super._process(delta)
		
	if is_attacking and not is_lying_on_floor:
		_swing_update(delta)

func use_weapon(direction: Vector2) -> void:
	try_attack(direction)

func try_attack(_direction: Vector2) -> void:
	if not is_ready() or is_attacking:
		return
	
	swing_speed = stats.swing_speed
	if holder is Player:
		swing_speed *= holder.fire_rate_multiplier
	is_attacking = true
	current_angle = -stats.swing_angle * 0.5
	swing_direction = 1
	rotation_degrees = current_angle
	#global_position = holder.global_position + direction.normalized() * stats.reach

	hitbox.monitoring = true
	hitbox.monitorable = true
	trigger_cooldown(holder.fire_rate_multiplier)

	AudioManager.play_sfx_positional(
		stats.attack_sound, global_position,
		stats.volume_db, stats.pitch_randomness
	)

func _swing_update(delta: float) -> void:
	var swing_step = swing_speed * delta
	current_angle += swing_step * swing_direction
	rotation_degrees = current_angle

	if current_angle >= stats.swing_angle * 0.5:
		is_attacking = false
		hitbox.monitoring = false
		hitbox.monitorable = false
		rotation_degrees = 0.0
		if is_instance_valid(holder) and holder is Enemy:
			holder.add_reward_event(GlobalConfig.RewardEvents["MISSED"], stored_state, stored_action)

# not used yet
func _adjust_hitbox():
	var shape = hitbox_shape.shape
	if shape is RectangleShape2D:
		# Set size along X (forward direction)
		shape.extents.x = 32 + stats.reach * 0.5  # Because extents is half-size, 32 cause weapon sprites are 32x32
		shape.extents.y = 32 
		
		# Shift the shape forward along X
		hitbox_shape.position.x = stats.reach * 0.5

func _on_area_2d_body_entered(body: Node2D) -> void:	
	if is_lying_on_floor:
		super._on_area_2d_body_entered(body)
	else:
		if holder is Player: 
			damage = (stats.attack_damage + holder.damage_flat_boost) * holder.damage_multiplier
			if randf() <= holder.crit_chance:
				damage *= holder.crit_damage_mul
		else:
			damage = stats.attack_damage
			
		if is_attacking and body != holder:
			if body is Player:  # Enemy hitting Player
				body.take_damage(damage)
				if is_instance_valid(holder):
					holder.add_reward_event(GlobalConfig.RewardEvents["HIT_PLAYER"], stored_state, stored_action)
			
			elif body is Enemy and holder is Player:  # Player hitting Enemy
				body.take_damage(damage)
			elif body is Enemy and holder is Enemy and EntitiesManager.friendly_fire: # Enemy vs Enemy
				body.take_damage(damage)
			elif body.get_parent() is Gate:
				body.get_parent().take_damage(damage)
