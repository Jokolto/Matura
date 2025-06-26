extends Node2D

#var enemy_scene: PackedScene = preload("res://scenes/entities/enemies/enemy.tscn")

func _ready() -> void:
	
	pass
	# the nodes do it themselves now
	#EntitiesManager.set_entities_node($Entities)
	#ProjectileManager.set_proj_node($Projectiles)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"): # Typically Escape
		$PauseMenu.toggle_pause()
