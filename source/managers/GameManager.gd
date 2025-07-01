extends Node
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var MenuScene = preload("res://scenes/GUI/menus/main_menu.tscn")
var PlayingScene = preload("res://scenes/level/level.tscn")
var PauseScene = preload("res://scenes/GUI/menus/pause_menu.tscn")
var DeathScene = preload("res://scenes/GUI/menus/death_menu.tscn")

var hud

var state = GameState.MENU
var current_scene: Node = null


func _ready() -> void:
	current_scene = get_tree().current_scene

func change_scene(to_scene: PackedScene):
	var new_scene = to_scene.instantiate()
	get_tree().get_root().add_child(new_scene)
	if current_scene:
		#print(str(current_scene) + "deleted")
		current_scene.queue_free()
	get_tree().current_scene = new_scene
	current_scene = new_scene

func _on_player_death():
	GameManager.change_scene(GameManager.DeathScene)
	
	
func _set_hud(thehud: Node):
	hud = thehud
	
func _get_hud():
	return hud
