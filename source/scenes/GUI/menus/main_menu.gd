extends Control


@onready var start_button: Button = $MarginContainer/VBoxContainer2/Buttons/PlayButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer2/Buttons/ExitButton
@onready var options_button: Button = $MarginContainer/VBoxContainer2/Buttons/OptionsButton
@onready var credits_button: Button = $MarginContainer/VBoxContainer2/Buttons/CreditsButton

func _ready():
	start_button.pressed.connect(on_start_pressed)
	quit_button.pressed.connect(on_quit_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)

func on_start_pressed():
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
