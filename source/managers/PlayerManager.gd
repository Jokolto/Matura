extends Node

var player: Node = null


func set_player(p: Node):
	p.died.connect(GameManager._on_player_death)
	player = p

func get_player() -> Node:
	return player
