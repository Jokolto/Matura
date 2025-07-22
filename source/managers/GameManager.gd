extends Node
#enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var Scenes = {
	"MENU": preload("res://scenes/GUI/menus/main_menu.tscn"),
	"PLAYING": preload("res://scenes/level/level.tscn"),
	"PAUSED": preload("res://scenes/GUI/menus/pause_menu.tscn"),
	"GAME_OVER": preload("res://scenes/GUI/menus/death_menu.tscn"),
	"OPTIONS": preload("res://scenes/GUI/menus/options_menu.tscn"),
	"CREDITS": preload("res://scenes/GUI/menus/credits_menu.tscn")
}

var hud

var state = "MENU"
var current_scene: Node = null

signal state_changed(state)

func _ready() -> void:
	state = "MENU"
	state_changed.emit(state)
	current_scene = get_tree().current_scene

func change_scene():
	var new_scene = Scenes[state].instantiate()
	get_tree().get_root().add_child(new_scene)
	if current_scene:
		#print(str(current_scene) + "deleted")
		current_scene.queue_free()
	get_tree().current_scene = new_scene
	current_scene = new_scene
	state_changed.emit(state)

func toggle_pause():
	get_tree().paused = not get_tree().paused
	# If needed, stop input to the world:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	var bus_index = AudioServer.get_bus_index("Music")

	if get_tree().paused:
		AudioServer.set_bus_effect_enabled(bus_index, 0, true)
		AudioServer.set_bus_volume_db(bus_index, -12) # lower volume too
	else:
		AudioServer.set_bus_effect_enabled(bus_index, 0, false)
		AudioServer.set_bus_volume_db(bus_index, 0)

func _on_player_death():
	state = "GAME_OVER"
	change_scene()
	
	
func _set_hud(thehud: Node):
	hud = thehud
	
func _get_hud():
	return hud
