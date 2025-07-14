extends Node
var next_enemy_id = 0

var entities_node: Node = null
var enemies_node: Node = null

var enemy_brains: Array = []

var enemies_per_wave: int = 0

var enemies_spawned: int = 0
var current_wave: int = 0
var wave_active: bool = false
var spawn_active: bool = false
var enemies_alive: int = 0

var wave_duration: float = 1000000
var wave_timer: float = 0.0
var player_heal_after_wave_percentage: float = 0.2 

signal wave_end
signal wave_start


func _ready() -> void:
	pass
	
func _process(delta):
	if not wave_active:
		return

	if wave_duration > 0:  
		wave_timer += delta

	if (enemies_spawned >= enemies_per_wave) or (wave_timer >= wave_duration):
		if enemies_alive <= 0:
			end_wave()
			return
		disable_spawning()


func disable_spawning():
	if spawn_active:
		spawn_active = false
		print("Spawning ended (enemy count)")


func start_wave():
	enemies_per_wave += 1
	current_wave += 1
	enemies_spawned = 0
	wave_timer = 0.0
	wave_active = true
	spawn_active = true
	enemy_brains = []
	print("Wave %d started" % current_wave)
	wave_start.emit()
	
	
func end_wave():
	wave_active = false
	
	print("Wave ended (enemies are dead)")
	wave_end.emit()
	
	
func get_next_enemy_id() -> int:
	var id = next_enemy_id
	next_enemy_id += 1
	return id

func get_entities():
	return entities_node.get_children()

func get_entities_amount():
	return entities_node.get_child_count()
	
func set_entities_node(node: Node):
	entities_node = node

func get_enemies():
	return enemies_node.get_children()

func get_enemy_brains():
	return enemy_brains

func set_enemies_node(node: Node):
	enemies_node = node

func _on_player_death():
	wave_active = false
	spawn_active = false

func _on_enemy_death(enemy_q_table):
	enemy_brains.append(enemy_q_table)
	enemies_alive -= 1
