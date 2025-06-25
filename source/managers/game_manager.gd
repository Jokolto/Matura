extends Node
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }
var state = GameState.MENU
var hud

func set_hud(hudarg: Node):
	hud = hudarg

func get_hud() -> Node:
	return hud
