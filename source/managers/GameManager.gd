extends Node
#enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var Scenes = {
	"MENU": preload("res://scenes/GUI/menus/main_menu.tscn"),
	"PLAYING": preload("res://scenes/level/level.tscn"),
	"PAUSED": preload("res://scenes/GUI/menus/pause_menu.tscn"),
	"GAME_OVER": preload("res://scenes/GUI/menus/death_menu.tscn"),
	"OPTIONS": preload("res://scenes/GUI/menus/options_menu.tscn"),
	"CREDITS": preload("res://scenes/GUI/menus/credits_menu.tscn"),
	"WIN": preload("res://scenes/GUI/menus/win_menu.tscn"),
	"CUTSCENE": preload("res://scenes/GUI/menus/cutscene.tscn")
}

var hud

var tutorial_enabled = true
var cutscene_enabled = true
var state = "MENU"
var current_scene: Node = null
var cursor_texture = preload("res://assets/sprites/v1.1 dungeon crawler 16X16 pixel pack/ui (new)/crosshair_1.png")
var stored_item_panels = []

# changed only in tutorialpanel, needed globally to not repeat tutorials however
var shown_tutorials: Dictionary = {} 
var tutorials_amount: int = 0 

signal state_changed(state)

func _ready() -> void:
	state = "MENU"
	state_changed.emit(state)
	current_scene = get_tree().current_scene

func change_scene():
	var new_scene = Scenes[state].instantiate()
	get_tree().get_root().add_child(new_scene)
	if state == "PLAYING":
		Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW,  Vector2(16, 16) )
	else:
		Input.set_custom_mouse_cursor(null)
	if current_scene:
		#print(str(current_scene) + "deleted")
		current_scene.queue_free()
	get_tree().current_scene = new_scene
	current_scene = new_scene
	state_changed.emit(state)

func toggle_pause():
	get_tree().paused = not get_tree().paused
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var bus_index = AudioServer.get_bus_index("Music")
	if get_tree().paused:
		
		Input.set_custom_mouse_cursor(null)
		AudioServer.set_bus_effect_enabled(bus_index, 0, true)
		AudioServer.set_bus_volume_db(bus_index, AudioManager.music_volume-12) # lower volume 
	else:
		if state == "PLAYING":
			Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW,  Vector2(16, 16) )
		AudioServer.set_bus_effect_enabled(bus_index, 0, false)
		AudioServer.set_bus_volume_db(bus_index, AudioManager.music_volume)


func _on_player_death():
	state = "GAME_OVER"
	change_scene()

func _on_win():
	state = "WIN"
	change_scene()
	
func _set_hud(thehud: Node):
	hud = thehud
	
func _get_hud():
	return hud
