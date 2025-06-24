extends CharacterBody2D

# -------------------------
# ─── Inspector Tweaks ──────────────────────────────────────────
# -------------------------
@export var move_speed: float = 200.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
var starting_gun: PackedScene = preload("res://scenes/weapons/guns/gun1.tscn")  # drag Bullet.tscn here

# -------------------------
# ─── Private State ────────────────────────────────────────────
# -------------------------
var dash_timer: float = 0.0
var is_dashing: bool = false

@onready var weapon_holder: Node2D = $Weaponholder
@onready var body_sprite: AnimatedSprite2D = $AnimatedSprite2D
var _current_gun: Node2D             # set in _ready()


func _ready() -> void:
	add_to_group("Player")
	if starting_gun != null:
		_current_gun = starting_gun.instantiate()
		weapon_holder.add_child(_current_gun)

func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector(
		"move_left",   # negative X
		"move_right",  # positive X
		"move_up",     # negative Y
		"move_down"    # positive Y
	)
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
	else:
		velocity = input_vector * move_speed
		if Input.is_action_just_pressed("dash"):
			is_dashing = true
			dash_timer = dash_duration
			# If the player isn’t pressing a direction, dash forward
			var dash_dir: Vector2 = input_vector if input_vector != Vector2.ZERO else Vector2.RIGHT
			velocity = dash_dir * dash_speed
	
	_update_animation(input_vector)

	move_and_slide()


func _process(_delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	_aim_weapon(mouse_pos)
	_handle_shoot(mouse_pos)


func _aim_weapon(mouse: Vector2) -> void:
	# 1) raw look-at
	weapon_holder.look_at(mouse)

	# 2) decide whether we’re ‘facing left’
	var ang_deg : float = wrapf(weapon_holder.rotation_degrees, 0.0, 360.0)
	var facing_left: bool = (ang_deg > 90.0 and ang_deg < 270.0)

	# 3) flip body sprite
	body_sprite.flip_h = facing_left

	# 4) mirror the entire holder (gun + muzzle) on the Y-axis
	weapon_holder.scale = Vector2(1, -1) if facing_left else Vector2(1, 1)


func _handle_shoot(mouse: Vector2) -> void:
	# Handle shooting
	if Input.is_action_just_pressed("shoot"):
		if _current_gun:
			_current_gun.try_fire(mouse)


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
		
