extends Node2D

# quite a useless script for now

func get_entities():
	return get_children()
	

func get_entities_amount():
	return get_child_count()
