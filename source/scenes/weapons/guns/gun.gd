extends Node2D


@export var fire_rate: float   = 5.0      # shots per second
@export var automatic: bool    = true
@export var spread_deg: float  = 0.0      # 0 = pinpoint
var bullet_scene: PackedScene = preload("res://scenes/weapons/bullets/bullet.tscn")

var _cooldown: float = 0.0
@onready var _gun_point: Marker2D = $gun_point


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta


func try_fire(target_pos: Vector2) -> void:
	if _cooldown > 0.0:                     # still cooling
		return
	_spawn_bullet(target_pos)
	_cooldown = 1.0 / fire_rate


func _spawn_bullet(target_pos: Vector2) -> void:
	var bullet := bullet_scene.instantiate()
	bullet.global_position = _gun_point.global_position

	# Apply spread
	var dir: Vector2 = (target_pos - bullet.global_position).normalized()
	bullet.rotation = dir.angle() 
	if spread_deg > 0.0:
		var half_rad: float = deg_to_rad(spread_deg) * 0.5
		var random_angle: float = randf_range(-half_rad, half_rad)
		dir = dir.rotated(random_angle)

	bullet.direction = dir
	get_tree().current_scene.get_node("Projectiles").add_child(bullet)
