extends CharacterBody2D
class_name Player

# -------------------------
# ─── Inspector Tweaks ──────────────────────────────────────────
# -------------------------
@export var move_speed: float = 200.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.25
@export var max_hp: float = 10.0
@export var hp: float = 10.0
@export var fire_rate_multiplier: float = 1
@export var damage_multiplier: float = 1
@export var damage_flat_boost: float = 0

var gun_scene: PackedScene = preload("res://scenes/weapons/guns/gun1.tscn")  
var default_gun_res: Resource = preload("res://resources/guns/handgun.tres")
var hurt_sound: AudioStream = preload("res://assets/audio/sfx/player/young-man-being-hurt-95628.mp3")

# -------------------------
# ─── Private State ────────────────────────────────────────────
# -------------------------
var dash_velocity = Vector2.ZERO
var is_dashing: bool = false

var vulnerable: bool = true
var invulnerable_period: float = 0.2

@onready var weapon_holder: Node2D = $Weaponholder
@onready var body_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var projectiles_node: Node = null

var gun_instance: Gun             
var current_gun_res: Resource = null

# -------------------------
# ─── Signals ────────────────────────────────────────────
# -------------------------
signal damaged(amount: int)
signal healed(amount: int)
signal died
signal gun_equiped(gun_texture)

func _ready() -> void:
	died.connect(_die)
	

func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector(
		"move_left",   # negative X
		"move_right",  # positive X
		"move_up",     # negative Y
		"move_down"    # positive Y
	)
	var dash_vel = _handle_dash(delta, input_vector)
	
	velocity = dash_vel if dash_vel != Vector2.ZERO else input_vector * move_speed
	
	_update_animation(input_vector)
	move_and_slide()


func _process(_delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	weapon_holder._aim_weapon(mouse_pos)
	_handle_shoot(mouse_pos)

func set_projectiles_node(node: Node):
	projectiles_node = node


func _handle_shoot(mouse: Vector2) -> void:
	# Handle shooting
	if gun_instance:
		if gun_instance.automatic:
			if Input.is_action_pressed("shoot"):
				gun_instance.try_fire(mouse)
		else:
			if Input.is_action_just_pressed("shoot"):
					gun_instance.try_fire(mouse)
	
		

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
	# ---- play the correct clip ----
	if input_vec != Vector2.ZERO:
		if body_sprite.animation != "run":
			body_sprite.play("run")
	else:
		if body_sprite.animation != "idle":
			body_sprite.play("idle")

	# ---- face the correct direction ----  // no need, gun aim decides the orientation
	#if input_vec.x != 0:
		#body_sprite.flip_h = input_vec.x < 0
		
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
	print("died!")


func equip_gun(gun_res: Resource = null):
	if gun_instance:
		gun_instance.queue_free()
	else:
		gun_res = default_gun_res
	
	gun_instance = gun_scene.instantiate()
	gun_instance.set_projectiles_node(projectiles_node)
	weapon_holder.add_child(gun_instance)
	gun_instance.stats = gun_res
	gun_instance.import_res_stats()
	gun_equiped.emit(gun_instance.sprite.texture)


func _on_dash_timer_timeout() -> void:
	is_dashing = false
	dash_velocity = Vector2.ZERO


func _on_invulnerability_timer_timeout() -> void:
	vulnerable = true
	

func heal(heal_value: int):
	var healable_hp = max_hp - hp
	if healable_hp <= 0:
		return
	
	if heal_value > healable_hp:
		hp += healable_hp
	else:
		hp += heal_value
		
	healed.emit(heal_value)
	

func _on_wave_end():
	heal(floor(EntitiesManager.player_heal_after_wave_percentage * max_hp))
