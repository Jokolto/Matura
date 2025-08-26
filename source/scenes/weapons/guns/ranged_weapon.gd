# gun.gd
class_name Gun
extends Weapon

@onready var _gun_point: Marker2D = $gun_point

var bullet_scene: PackedScene = preload("res://scenes/weapons/bullets/bullet.tscn")

var final_damage: float = 0.0

func _ready():
	super._ready()
	weapon_type = GlobalConfig.EnemyTypes.Ranged


func use_weapon(target_pos: Vector2) -> void:
	try_fire(target_pos)

func try_fire(target_pos: Vector2) -> void:
	if not is_ready():
		return
	
	
	for bullet in range(stats.bullets_amount):
		_spawn_bullet(target_pos)
	
	AudioManager.play_sfx_positional(
		stats.on_shoot_sound, global_position,
		stats.shoot_sound_volume_db, stats.shoot_sound_pitch_randomness
	)

	trigger_cooldown(holder.fire_rate_multiplier)

func _spawn_bullet(target_pos: Vector2) -> void:
	var bullet = bullet_scene.instantiate()
	bullet.projectiles_node = projectiles_node
	bullet.global_position = _gun_point.global_position
	bullet.gun_node = self
	bullet.shooter = holder

	var dir: Vector2 = (target_pos - bullet.global_position).normalized()
	bullet.rotation = dir.angle()

	if stats.spread_deg > 0.0:
		var half_rad = deg_to_rad(stats.spread_deg) * 0.5
		var random_angle = randf_range(-half_rad, half_rad)
		dir = dir.rotated(random_angle)

	bullet.direction = dir
	bullet.damage = stats.bullet_damage
	bullet.shooting_range = stats.shooting_range
	bullet.speed = stats.bullet_speed
	bullet.piercing = stats.bullet_piercing

	if holder is Player:
		final_damage = (stats.bullet_damage + holder.damage_flat_boost) * holder.damage_multiplier
		bullet.damage = final_damage
		projectiles_node.player_projectile_node.add_child(bullet)
	else:
		bullet.shot_at_state = stored_state
		bullet.stored_action = stored_action
		projectiles_node.add_child(bullet)
		
