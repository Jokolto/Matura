extends Node

@export var spawn_rate: float = 0.5  # Seconds between spawns
@export var enemy_scene: PackedScene = preload("res://scenes/entities/enemies/melee/enemy.tscn")
@export var ranged_enemy_scene: PackedScene = preload("res://scenes/entities/enemies/ranged/ranged_enemy.tscn")

@onready var enemies_node = $"../../Entities/Enemies"
@onready var level_node = $"../.."

var player = null  # set in level
var projectiles_node = null # set in level
var spawners: Array = []
var enemy_pool: Dictionary = {}
var timer := 0.0

signal enemy_spawned

func _ready() -> void:
	spawners = get_children()

func _process(delta: float) -> void:
	timer += delta
	if timer >= spawn_rate and EntitiesManager.spawn_active:
		timer = 0.0
		spawn_enemy()

func set_player(player_scene):
	player = player_scene

func spawn_enemy() -> void:
	enemy_pool = {
	enemy_scene: func(wave): return 100, #max(100 - wave * 10, 20)
	ranged_enemy_scene: func(wave): return 0 #min(wave * 10, 80)
	}
	
	if not is_instance_valid(player):
		print("no player -> no enemies")
		return
	
	if not enemy_spawned.is_connected(GameManager.hud._on_enemy_spawned):
		enemy_spawned.connect(GameManager.hud._on_enemy_spawned)
	
	var chosen_enemy_scene = choose_enemy(EntitiesManager.current_wave)
	var enemy = chosen_enemy_scene.instantiate()
	
	enemy.global_position = get_spawn_position()
	enemy.set_player(player)
	enemy.set_projectiles_node(projectiles_node)
	enemy.set_enemies_node(enemies_node)

	EntitiesManager.enemies_spawned += 1
	EntitiesManager.enemies_alive += 1
	enemies_node.add_child(enemy)
	enemy_spawned.emit()
	#print("Enemy was spawned!")


func choose_enemy(wave: int) -> PackedScene:
	var weights = {}
	var total_weight = 0.0
	
	for enemy in enemy_pool.keys():
		var weight = float(enemy_pool[enemy].call(wave))
		weights[enemy] = weight
		total_weight += weight
	
	var rand = randf() * total_weight
	var cumulative = 0.0
	
	for enemy in weights.keys():
		cumulative += weights[enemy]
		if rand <= cumulative:
			return enemy
	
	return weights.keys()[0]  # fallback

func get_spawn_position() -> Vector2:
	#var rand_ind = randi() % spawners.size()
	var spawner = spawners.pick_random()
	var rand_spawn_area = spawner.spawn_area
	return rand_spawn_area.get_random_position()


func set_projectiles_node(node: Node):
	projectiles_node = node
