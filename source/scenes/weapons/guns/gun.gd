extends Node2D


@export var fire_rate: float   = 5.0     # shots per second
@export var automatic: bool    = true
@export var spread_deg: float  = 5.0    # 0 = pinpoint
@export var bullet_damage: float = 1.0

var final_damage: float = 0.0             # Calculated when shot 
var bullet_scene: PackedScene = preload("res://scenes/weapons/bullets/bullet.tscn")
var shooter: CharacterBody2D = null

var _cooldown: float = 0.0
@onready var _gun_point: Marker2D = $gun_point

func _ready() -> void:
	shooter = get_parent().get_parent()
	fire_rate *= shooter.fire_rate_multiplier
		

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta


func try_fire(target_pos: Vector2) -> void:
	if _cooldown > 0.0:                     # still cooling
		return
	_spawn_bullet(target_pos)
	_cooldown = 1.0 / (fire_rate)


func _spawn_bullet(target_pos: Vector2) -> void:
	var bullet := bullet_scene.instantiate()
	bullet.global_position = _gun_point.global_position
	bullet.gun_node = self
	bullet.shooter = shooter
	
	# Apply spread
	var dir: Vector2 = (target_pos - bullet.global_position).normalized()
	bullet.rotation = dir.angle() 
	if spread_deg > 0.0:
		var half_rad: float = deg_to_rad(spread_deg) * 0.5
		var random_angle: float = randf_range(-half_rad, half_rad)
		dir = dir.rotated(random_angle)

	# Apply other stats 
	final_damage = (bullet_damage + PlayerManager.player.damage_flat_boost) * PlayerManager.player.damage_multiplier
	#print(final_damage, PlayerManager.player.damage_flat_boost, PlayerManager.player.damage_multiplier)
	bullet.damage = final_damage
	
	bullet.direction = dir
	ProjectileManager.projectile_node.add_child(bullet)
