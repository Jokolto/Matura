extends CanvasLayer

@onready var try_again_button: Button = $Panel/Buttons/PlayButton
@onready var menu_button: Button = $Panel/Buttons/MenuButton

func _ready():
	try_again_button.pressed.connect(_on_try_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	#hide()


func _on_try_again_pressed():
	GameManager.state = "PLAYING"
	GameManager.change_scene()

func _on_menu_pressed():
	get_tree().paused = false
	GameManager.state = "MENU"
	GameManager.change_scene()
