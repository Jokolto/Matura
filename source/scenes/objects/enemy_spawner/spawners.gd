extends Node

@export var spawn_rate: float = 0.5  # Seconds between spawns
@export var enemy_scene: PackedScene = preload("res://scenes/entities/enemies/melee/enemy.tscn")
@export var ranged_enemy_scene: PackedScene = preload("res://scenes/entities/enemies/ranged/ranged_enemy.tscn")

var melee_weapons_res: ResourceGroup = preload("res://resources/weapons/melee.tres")
var ranged_weapons_res: ResourceGroup = preload("res://resources/weapons/guns.tres")

var melee_weapons_pool = []
var ranged_weapons_pool = []
var rarity_distribution: Dictionary = {1 : 0.65,  2 : 0.2,  3 : 0.1, 4 : 0.05}  # for weapon rarity

@onready var enemies_node = $"../../Entities/Enemies"
@onready var level_node = $"../.."
@onready var item_manager = $"../../ItemManager"  # literally just for one method - get random item
@onready var pickup_node = $"../Pickups"

var player = null  # set in level
var projectiles_node = null # set in level
var spawners: Array = []
var enemy_pool: Dictionary = {}
var timer := 0.0
	
signal enemy_spawned

func _ready() -> void:
	spawners = get_children()
	melee_weapons_res.load_all_into(melee_weapons_pool)
	ranged_weapons_res.load_all_into(ranged_weapons_pool)

func _process(delta: float) -> void:
	timer += delta
	if timer >= spawn_rate and EntitiesManager.spawn_active:
		timer = 0.0
		spawn_enemy()

func set_player(player_scene):
	player = player_scene

func spawn_enemy() -> void:	
	if not is_instance_valid(player):
		return
	
	if not enemy_spawned.is_connected(GameManager.hud._on_enemy_spawned):
		enemy_spawned.connect(GameManager.hud._on_enemy_spawned)
	
	var enemy = ranged_enemy_scene.instantiate() as RangedEnemy
	var chosen_weapon_pool = choose_enemy_type(EntitiesManager.current_wave) # chooses between melee weapons or ranged, where ranged is rarer
	var chosen_weapon_res = item_manager.get_random_item(chosen_weapon_pool, [], rarity_distribution)
	
	enemy.global_position = get_spawn_position()
	enemy.set_player(player)
	enemy.set_projectiles_node(projectiles_node)
	enemy.set_enemies_node(enemies_node)
	enemy.set_pickup_node(pickup_node)
	
	enemy.move_speed *= EntitiesManager.enemy_speed_mul
	EntitiesManager.enemies_spawned += 1
	EntitiesManager.enemies_alive += 1
	enemies_node.add_child(enemy)
	enemy.equip_weapon(chosen_weapon_res)
	enemy_spawned.emit()
	#print("Enemy was spawned!")



func get_spawn_position() -> Vector2:
	#var rand_ind = randi() % spawners.size()
	var spawner = spawners.pick_random()
	var rand_spawn_area = spawner.spawn_area
	return rand_spawn_area.get_random_position()

func get_ranged_chance(wave: int) -> float:
	var capped_wave = clamp(wave, 1, 20)
	return lerp(0.0, 0.4, (capped_wave - 1) / 19.0)  # 0% to 40% over 20 waves
	
func choose_enemy_type(wave: int) -> Array:
	var ranged_chance = get_ranged_chance(wave)
	if randf() < ranged_chance:
		return ranged_weapons_pool
	else:
		return melee_weapons_pool

func set_projectiles_node(node: Node):
	projectiles_node = node
