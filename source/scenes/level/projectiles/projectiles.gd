extends Node
var next_proj_id = 0
var proj_amount = 0
@onready var level_node = $".."

func get_next_proj_id() -> int:
	var id = next_proj_id
	next_proj_id += 1
	proj_amount += 1
	return id

func _ready() -> void:
	pass
