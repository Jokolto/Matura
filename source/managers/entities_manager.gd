extends Node
var next_enemy_id = 0
var entities_node: Node = null

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
