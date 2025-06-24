extends Node2D

@export var spawn_rate: float = 2.0  # Seconds between spawns
@export var enemy_scene: PackedScene = preload("res://scenes/entities/enemies/enemy.tscn")

@onready var spawn_area = $SpawnArea
@onready var player = get_tree().get_first_node_in_group("Player")

var timer := 0.0

func _process(delta: float) -> void:
	timer += delta
	if timer >= spawn_rate:
		timer = 0.0
		spawn_enemy()


func spawn_enemy() -> void:
	if not is_instance_valid(player):
		print("no player -> no enemies")
		return

	var enemy = enemy_scene.instantiate()
	enemy.global_position = get_spawn_position()
	enemy.player = player
	get_tree().current_scene.get_node("Entities").add_child(enemy)
	print("Enemy was spawned!")


func get_spawn_position() -> Vector2:
	return spawn_area.get_random_position()
