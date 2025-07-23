extends CanvasLayer

@onready var resume_button: Button = $Panel/VBoxContainer/Resume
@onready var menu_button: Button = $Panel/VBoxContainer/MainMenu

func _ready():
	resume_button.pressed.connect(_on_resume_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	hide()


func _on_resume_pressed():
	GameManager.toggle_pause()
	visible = false

func _on_menu_pressed():
	Input.set_custom_mouse_cursor(null)
	GameManager.toggle_pause()
	GameManager.state = "MENU"
	GameManager.change_scene()

func _on_pause():
	visible = true
