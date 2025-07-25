extends Control

@onready var play_again_button: TextureButton = $Buttons/PlayButton
@onready var credits_button: TextureButton = $Buttons/CreditsButton
@onready var menu_button: TextureButton = $Buttons/MenuButton

func _ready():
	play_again_button.pressed.connect(_on_play_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	#hide()


func _on_play_again_pressed():
	GameManager.state = "PLAYING"
	GameManager.change_scene()

func _on_menu_pressed():
	get_tree().paused = false
	GameManager.state = "MENU"
	GameManager.change_scene()
	
	
func _on_credits_pressed():
	GameManager.state = "CREDITS"
	GameManager.change_scene()
