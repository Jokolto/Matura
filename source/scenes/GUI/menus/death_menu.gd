extends CanvasLayer

@onready var resume_button: Button = $Panel/VBoxContainer/TryAgain
@onready var menu_button: Button = $Panel/VBoxContainer/MainMenu

func _ready():
	resume_button.pressed.connect(_on_try_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	#hide()


func _on_try_again_pressed():
	GameManager.change_scene(GameManager.PlayingScene)

func _on_menu_pressed():
	get_tree().paused = false
	# Load your menu scene
	GameManager.change_scene(GameManager.MenuScene)
