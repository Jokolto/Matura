# melee_weapon.gd
class_name MeleeWeapon
extends Weapon

@onready var area: Area2D = $Area2D

var is_attacking: bool = false
var current_angle: float = 0.0
var swing_direction: int = 1

func _ready():
	holder = get_holder()
	weapon_type = WeaponType.MELEE

func _process(delta: float) -> void:
	super._process(delta)

	if is_attacking:
		_swing_update(delta)

func use_weapon(direction: Vector2) -> void:
	try_attack(direction)

func try_attack(direction: Vector2) -> void:
	if not is_ready() or is_attacking:
		return

	is_attacking = true
	current_angle = -stats.swing_angle * 0.5
	swing_direction = 1
	rotation_degrees = current_angle
	#global_position = holder.global_position + direction.normalized() * stats.reach

	area.monitoring = true
	area.monitorable = true
	trigger_cooldown(holder.fire_rate_multiplier)

	AudioManager.play_sfx_positional(
		stats.attack_sound, global_position,
		stats.volume_db, stats.pitch_randomness
	)

func _swing_update(delta: float) -> void:
	var swing_step = stats.swing_speed * delta
	current_angle += swing_step * swing_direction
	rotation_degrees = current_angle

	if current_angle >= stats.swing_angle * 0.5:
		is_attacking = false
		area.monitoring = false
		area.monitorable = false
		rotation_degrees = 0.0



func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Enemy or body is Player and body != holder:
		body.take_damage(stats.attack_damage)
	elif body.get_parent() is Gate:
			body.get_parent().take_damage(stats.attack_damage)
