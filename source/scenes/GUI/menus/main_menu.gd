extends Control


@onready var start_button: Button = $MarginContainer/VBoxContainer2/Buttons/PlayButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer2/Buttons/ExitButton

func _ready():
	start_button.pressed.connect(on_start_pressed)
	quit_button.pressed.connect(on_quit_pressed)

func on_start_pressed():
	GameManager.state = "PLAYING"
	GameManager.change_scene()

func on_quit_pressed():
	get_tree().quit()
