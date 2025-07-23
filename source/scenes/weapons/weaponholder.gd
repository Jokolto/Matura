extends Node2D

var facing_left: bool = false
var base_x: float


func _ready():
	base_x = position.x  # Cache original local X position

func _aim_weapon(pos: Vector2) -> void:
	# Look at the target
	if (global_position - pos).length() > 50:
		look_at(pos)

	# Angle in degrees, wrapped to [0, 360)
	var ang_deg: float = wrapf(rotation_degrees, 0.0, 360.0)

	# Only update facing_left if the angle is clearly in one half
	if ang_deg > 120 and ang_deg < 240:
		facing_left = true
	elif ang_deg < 60 or ang_deg > 300:
		facing_left = false
	# else: keep previous direction (deadzone between 60-120 and 240-300)

	# Flip player sprite
	if "body_sprite" in owner:
		owner.body_sprite.flip_h = facing_left
	
	scale = Vector2(1, -1) if facing_left else Vector2(1, 1)
	# Mirror position across Y-axis (negate X)
	position.x = -base_x if facing_left else base_x
