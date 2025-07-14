extends Node

var shared_q_table: Dictionary = {}

func _ready() -> void:
	EntitiesManager.wave_end.connect(_on_wave_end)

func gather_enemy_brains(enemy_q_tables: Array):
	
	shared_q_table.clear()

	for individual_table in enemy_q_tables:
		for state in individual_table.keys():
			if !shared_q_table.has(state):
				shared_q_table[state] = {}

			for action in individual_table[state].keys():
				var value = individual_table[state][action]
				if !shared_q_table[state].has(action):
					shared_q_table[state][action] = []
				shared_q_table[state][action].append(value)

	# Average the values  
	for state in shared_q_table.keys():
		for action in shared_q_table[state].keys():
			var values = shared_q_table[state][action]
			var total := 0.0
			for v in values:
				total += v
			var avg := total / float(values.size())
			
			shared_q_table[state][action] = avg

func get_shared_q_table() -> Dictionary:
	return shared_q_table
	

func _on_wave_end():
	gather_enemy_brains(EntitiesManager.get_enemy_brains())
