extends Control

@onready var play_again_button: Button = $VboxContainer/HboxContainer/Buttons/PlayAgainButton
@onready var credits_button: Button = $VboxContainer/HboxContainer/Buttons/CreditsButton
@onready var menu_button: Button = $VboxContainer/HboxContainer/Buttons/MenuButton

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
