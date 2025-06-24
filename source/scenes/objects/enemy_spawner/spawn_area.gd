extends Node2D

func get_random_position() -> Vector2:
	var shape = $Area2D/CollisionShape2D.shape as RectangleShape2D
	var rect_size = shape.extents * 2.0
	var offset = Vector2(
		randf_range(0, rect_size.x),
		randf_range(0, rect_size.y)
	) - shape.extents
	return global_position + offset
