extends Node2D

@export var spawn_rate: float = 2.0  # Seconds between spawns
@export var enemy_scene: PackedScene = preload("res://scenes/entities/enemies/enemy.tscn")

@onready var spawn_area = $SpawnArea
@onready var player = PlayerManager.get_player()

var timer := 0.0

signal enemy_spawned

func _ready() -> void:
	spawn_rate = randf_range(0.3, 1.5)
	
func _process(delta: float) -> void:
	timer += delta
	if timer >= spawn_rate and EntitiesManager.spawn_active:
		timer = 0.0
		spawn_enemy()

func spawn_enemy() -> void:
	if not is_instance_valid(player):
		print("no player -> no enemies")
		return
	
	if not enemy_spawned.is_connected(GameManager.hud._on_enemy_spawned):
		enemy_spawned.connect(GameManager.hud._on_enemy_spawned)
		
	var enemy = enemy_scene.instantiate()
	enemy.global_position = get_spawn_position()
	enemy.player = player
	EntitiesManager.enemies_spawned += 1
	EntitiesManager.enemies_alive += 1
	EntitiesManager.enemies_node.add_child(enemy)
	enemy_spawned.emit()
	print("Enemy was spawned!")

func get_spawn_position() -> Vector2:
	return spawn_area.get_random_position()
