extends CharacterBody2D
class_name Player

@export var move_speed: float = 200.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.25
@export var max_hp: float = 10.0
@export var hp: float = 10.0
@export var fire_rate_multiplier: float = 1
@export var damage_multiplier: float = 1
@export var damage_flat_boost: float = 0

var weapon_scene: PackedScene
var default_weapon_res: Resource = preload("res://resources/guns/melee/sword.tres")


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

func _ready() -> void:
	died.connect(_die)
	_equip_weapon(default_weapon_res)

func _physics_process(delta: float) -> void:
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dash_vel = _handle_dash(delta, input_vector)
	velocity = dash_vel if dash_vel != Vector2.ZERO else input_vector * move_speed
	_update_animation(input_vector)
	move_and_slide()

func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	weapon_holder._aim_weapon(mouse_pos)
	_handle_weapon_use(mouse_pos)

func set_projectiles_node(node: Node):
	projectiles_node = node

func _handle_weapon_use(target_pos: Vector2) -> void:
	if weapon_instance and weapon_instance.is_ready():
		var is_auto = weapon_instance.stats.automatic
		if is_auto:
			if Input.is_action_pressed("shoot"):
				weapon_instance.use_weapon(target_pos)
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
		emit_signal("died")

func _die() -> void:
	Logger.log("Player died!", "INFO")

func _equip_weapon(res: Resource = null):
	if weapon_instance:
		weapon_instance.queue_free()

	weapon_res = res if res else default_weapon_res
	
	var scene = load(weapon_res.scene_path) as PackedScene
	weapon_instance = scene.instantiate() as Weapon
	
	weapon_instance.import_res_stats(weapon_res)

	if weapon_instance.has_method("set_projectiles_node") and projectiles_node:
		weapon_instance.set_projectiles_node(projectiles_node)

	weapon_holder.add_child(weapon_instance)

	if weapon_instance.has_node("Sprite2D"):
		Logger.log("Player equipped weapon %s" % [weapon_res.resource_name], "DEBUG")
		var sprite = weapon_instance.get_node("Sprite2D") as Sprite2D
		sprite.texture = weapon_res.sprite
		weapon_equipped.emit(sprite.texture)

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
