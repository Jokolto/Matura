extends Node2D


func _aim_weapon(position: Vector2) -> void:
	# 1) raw look-at
	look_at(position)

	# 2) decide whether we’re ‘facing left’
	var ang_deg : float = wrapf(rotation_degrees, 0.0, 360.0)
	var facing_left: bool = (ang_deg > 90.0 and ang_deg < 270.0)

	# 3) flip body sprite
	if "body_sprite" in owner:
		owner.body_sprite.flip_h = facing_left

	# 4) mirror the entire holder (gun + muzzle) on the Y-axis
	scale = Vector2(1, -1) if facing_left else Vector2(1, 1)
	
