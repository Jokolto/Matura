extends Control


@onready var start_button: TextureButton = $Panel/Buttons/PlayButton
@onready var options_button: TextureButton = $Panel/Buttons/OptionsButton
@onready var credits_button: TextureButton = $Panel/Buttons/CreditsButton
@onready var quit_button: TextureButton = $Panel/Buttons/ExitButton

func _ready():
	start_button.pressed.connect(on_start_pressed)
	quit_button.pressed.connect(on_quit_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)

func on_start_pressed():
	if GameManager.cutscene_enabled:
		GameManager.state = "CUTSCENE"
	else:
		GameManager.state = "PLAYING"
	GameManager.change_scene()

func on_quit_pressed():
	get_tree().quit()

func _on_options_pressed():
	GameManager.state = "OPTIONS"
	GameManager.change_scene()
	
func _on_credits_pressed():
	GameManager.state = "CREDITS"
	GameManager.change_scene()
