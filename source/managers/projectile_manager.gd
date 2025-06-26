extends Node
var next_proj_id = 0
var proj_amount = 0
var projectile_node: Node = null

func get_next_proj_id() -> int:
	var id = next_proj_id
	next_proj_id += 1
	proj_amount += 1
	return id


func set_proj_node(n: Node):
	projectile_node = n

func get_proj_node() -> Node:
	return projectile_node
