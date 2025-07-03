extends Node
#enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var Scenes = {
	"MENU": preload("res://scenes/GUI/menus/main_menu.tscn"),
	"PLAYING": preload("res://scenes/level/level.tscn"),
	"PAUSED": preload("res://scenes/GUI/menus/pause_menu.tscn"),
	"GAME_OVER": preload("res://scenes/GUI/menus/death_menu.tscn")
}
var hud

var state = "MENU"
var current_scene: Node = null


func _ready() -> void:
	current_scene = get_tree().current_scene

func change_scene():
	var new_scene = Scenes[state].instantiate()
	get_tree().get_root().add_child(new_scene)
	if current_scene:
		#print(str(current_scene) + "deleted")
		current_scene.queue_free()
	get_tree().current_scene = new_scene
	current_scene = new_scene

func _on_player_death():
	state = "GAME_OVER"
	change_scene()
	
	
func _set_hud(thehud: Node):
	hud = thehud
	
func _get_hud():
	return hud
