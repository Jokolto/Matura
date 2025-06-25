extends Node2D

#var enemy_scene: PackedScene = preload("res://scenes/entities/enemies/enemy.tscn")

func _ready() -> void:
	EntitiesManager.set_entities_node($Entities)
