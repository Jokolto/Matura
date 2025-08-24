extends Label

@export var float_speed: float = 40.0
@export var lifetime: float = 0.8

var time_alive := 0.0

func _process(delta: float) -> void:
	time_alive += delta
	position.y -= float_speed * delta  # move upwards
	modulate.a = 1.0 - (time_alive / lifetime)  # fade out alpha

	if time_alive >= lifetime:
		queue_free()
