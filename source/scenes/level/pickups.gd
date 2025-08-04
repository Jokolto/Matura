extends Node2D

func _ready() -> void:
	EntitiesManager.wave_end.connect(_on_wave_end)
	
func _on_wave_end(_fitness):
	for child in get_children():
		child.queue_free()
