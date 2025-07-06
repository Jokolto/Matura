class_name Gun extends Node2D

@onready var _gun_point: Marker2D = $gun_point
@onready var sprite: Sprite2D = $Sprite2D

@export var fire_rate: float   # shots per second
@export var automatic: bool
@export var spread_deg: float    # 0 = pinpoint
@export var bullet_damage: float
@export var bullets_amount: int
@export var piercing: int
@export var shooting_range: float
@export var bullet_speed: float

var on_shoot_sound: AudioStream
var shoot_sound_volume: float
var shoot_sound_pitch_randomness: float

var final_damage: float = 0.0             # Calculated when shot 
var bullet_scene: PackedScene = preload("res://scenes/weapons/bullets/bullet.tscn")
@export var stats: Resource = preload("res://resources/guns/handgun.tres")

var shooter: CharacterBody2D = null


var _cooldown: float = 0.0

var projectiles_node: Node = null

func _ready() -> void:
	# import stats from resource
	fire_rate = stats.fire_rate
	automatic = stats.automatic
	spread_deg = stats.spread_deg
	bullet_damage = stats.bullet_damage
	bullets_amount = stats.bullets_amount
	shooting_range = stats.shooting_range
	bullet_speed = stats.bullet_speed
	piercing = stats.bullet_piercing
	sprite.texture = stats.sprite
	
	on_shoot_sound = stats.stream
	shoot_sound_volume = stats.volume_db
	shoot_sound_pitch_randomness = stats.pitch_randomness
	
	shooter = get_parent().get_parent()
	fire_rate *= shooter.fire_rate_multiplier
		

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta

func set_projectiles_node(projectiles_node_passed):
	projectiles_node = projectiles_node_passed

func try_fire(target_pos: Vector2) -> void:
	if _cooldown > 0.0:                     # still cooling
		return
	for bullet in range(bullets_amount):
		_spawn_bullet(target_pos)
		
	AudioManager.play_sfx_positional(on_shoot_sound, global_position, shoot_sound_volume, shoot_sound_pitch_randomness)
	_cooldown = 1.0 / (fire_rate)


func _spawn_bullet(target_pos: Vector2) -> void:
	var bullet := bullet_scene.instantiate()
	bullet.projectiles_node = projectiles_node
	bullet.global_position = _gun_point.global_position
	bullet.gun_node = self
	bullet.shooter = shooter
	
	bullet.damage = bullet_damage
	bullet.shooting_range = shooting_range
	bullet.speed = bullet_speed
	bullet.piercing = piercing
	
	# Apply spread
	var dir: Vector2 = (target_pos - bullet.global_position).normalized()
	bullet.rotation = dir.angle() 
	if spread_deg > 0.0:
		var half_rad: float = deg_to_rad(spread_deg) * 0.5
		var random_angle: float = randf_range(-half_rad, half_rad)
		dir = dir.rotated(random_angle)

	# Apply other stats 
	if shooter is Player:
		final_damage = (bullet_damage + shooter.damage_flat_boost) * shooter.damage_multiplier
		bullet.damage = final_damage
		
	#print(final_damage, PlayerManager.player.damage_flat_boost, PlayerManager.player.damage_multiplier)
	
	
	bullet.direction = dir
	projectiles_node.add_child(bullet)
