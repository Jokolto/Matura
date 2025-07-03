extends CanvasLayer

@onready var resume_button: Button = $Panel/VBoxContainer/Resume
@onready var menu_button: Button = $Panel/VBoxContainer/MainMenu

func _ready():
	resume_button.pressed.connect(_on_resume_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	hide()

func toggle_pause():
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused
	# If needed, stop input to the world:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_resume_pressed():
	toggle_pause()

func _on_menu_pressed():
	get_tree().paused = false
	# Load your menu scene
	GameManager.state = "MENU"
	GameManager.change_scene()
