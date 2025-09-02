extends CharacterBody2D
class_name Player

@export var move_speed: float = 200.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.25
@export var max_hp: float = 15.0
@export var hp: float = 15.0
@export var fire_rate_multiplier: float = 1
@export var damage_multiplier: float = 1
@export var damage_flat_boost: float = 0
@export var crit_chance: float = 0.0
@export var crit_damage_mul: float = 2
@export var contact_damage: float = 0
@export var life_steal: float = 0
@export var damage_reduction: float = 0
@export var dodge_chance: float = 0

# item specific
var weapons_automatic_override = false

var fire_dmg: float = 0
var fire_duration: float = 0 

var stones_throw_amount: int = 0


var weapon_scene: PackedScene # will be assigned automatically from resource
var default_weapon_res: Resource = preload("res://resources/weapons/melee/hammer.tres")
@export var nearby_pickups: Array[Weapon] = []  

var hurt_sound: AudioStream = preload("res://assets/audio/sfx/player/young-man-being-hurt-95628.mp3")

var dash_velocity = Vector2.ZERO
var is_dashing: bool = false
var vulnerable: bool = true
var invulnerable_period: float = 0.2

@onready var weapon_holder: Node2D = $Weaponholder
@onready var body_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var projectiles_node: Node = null

var weapon_instance: Weapon = null
var weapon_res: Resource = null

signal damaged(amount: int)
signal healed(amount: int)
signal died
signal weapon_equipped(texture)
signal weapon_nearby
signal shot(gun)

func _physics_process(delta: float) -> void:
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var dash_vel = _handle_dash(delta, input_vector)
	velocity = dash_vel if dash_vel != Vector2.ZERO else input_vector * move_speed
	_update_animation(input_vector)
	move_and_slide()

func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	weapon_holder._aim_weapon(mouse_pos)
	_handle_weapon_use(mouse_pos)
	_handle_pickups()

func set_projectiles_node(node: Node):
	projectiles_node = node

func _handle_pickups():
	if nearby_pickups.size() > 0:
		weapon_nearby.emit()
		if Input.is_action_just_pressed("interact"):
			# Pick the closest one
			var nearest = nearby_pickups[0]
			var dist = global_position.distance_squared_to(nearest.global_position)
			for pickup in nearby_pickups:
				var d = global_position.distance_squared_to(pickup.global_position)
				if d < dist:
					nearest = pickup
					dist = d
			nearest.on_pickup(self)

func _handle_weapon_use(target_pos: Vector2) -> void:
	if weapon_instance and weapon_instance.is_ready():
		var is_auto = weapon_instance.stats.automatic or weapons_automatic_override
		if is_auto:
			if Input.is_action_pressed("shoot"):
				weapon_instance.use_weapon(target_pos)
				if weapon_instance.weapon_type == GlobalConfig.WeaponType['RANGED']:
					shot.emit(weapon_instance)
		else:
			if Input.is_action_just_pressed("shoot"):
				weapon_instance.use_weapon(target_pos)

func _handle_dash(_delta: float, input_vector: Vector2) -> Vector2:
	if is_dashing:
		return dash_velocity

	if Input.is_action_just_pressed("dash"):
		$Timers/DashTimer.start(dash_duration)
		is_dashing = true
		dash_velocity = (input_vector.normalized() if input_vector != Vector2.ZERO else Vector2.RIGHT) * dash_speed
		return dash_velocity
	return Vector2.ZERO

func _update_animation(input_vec: Vector2) -> void:
	if input_vec != Vector2.ZERO:
		if body_sprite.animation != "run":
			body_sprite.play("run")
	else:
		if body_sprite.animation != "idle":
			body_sprite.play("idle")

func take_damage(damage: float) -> void:
	if vulnerable:
		hp -= damage
		damaged.emit(damage)
		$Timers/InvulnerabilityTimer.start(invulnerable_period)
		AudioManager.play_sfx(hurt_sound)
		vulnerable = false
		if hp <= 0:
			_die()
	

func _die() -> void:
	died.emit()
	Logger.log("Player died!", "INFO")
	queue_free()
	
func _equip_weapon(res: Resource = null):
	if weapon_instance:
		weapon_instance.queue_free()

	weapon_res = res if res else default_weapon_res
	
	var scene = load(weapon_res.scene_path) as PackedScene
	weapon_instance = scene.instantiate() as Weapon
	
	weapon_instance.import_res_stats(weapon_res)
	weapon_instance.set_projectiles_node(projectiles_node)
	weapon_holder.add_child(weapon_instance)
	Logger.log("Player equipped weapon %s" % [weapon_res.resource_name], "DEBUG")
	var sprite = weapon_instance.sprite as Sprite2D
	sprite.texture = weapon_res.sprite
	weapon_equipped.emit(res)

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	dash_velocity = Vector2.ZERO

func _on_invulnerability_timer_timeout() -> void:
	vulnerable = true

func heal(heal_value: int):
	var healable_hp = max_hp - hp
	if healable_hp <= 0:
		return

	var actual_heal = min(heal_value, healable_hp)
	hp += actual_heal
	healed.emit(actual_heal)

func _on_wave_end(_fitness_dict):
	heal(floor(EntitiesManager.player_heal_after_wave_percentage * max_hp))
	
