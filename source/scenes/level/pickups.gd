extends Node2D

func _ready() -> void:
	EntitiesManager.wave_end.connect(_on_wave_end)
	

func _process(_delta: float) -> void:
	# if no other pickups, turn on infinite ammo to prevent hardlock
	if not GlobalConfig.EXPERIMENTING:
		GlobalConfig.infinite_ammo_ranged = get_child_count() <= 0
		

func _on_wave_end(_fitness):
	pass
	#for child in get_children():
		#child.queue_free()
