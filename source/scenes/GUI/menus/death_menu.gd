extends CanvasLayer

@onready var try_again_button: TextureButton = $Panel/Buttons/PlayButton
@onready var menu_button: TextureButton = $Panel/Buttons/MenuButton
@onready var items_container = $Panel/ItemsContainer
@onready var stat_label = $Panel/statsvcontainer/statLabel

func _ready():
	var item_panels = GameManager.stored_item_panels
	try_again_button.pressed.connect(_on_try_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	for item_panel in item_panels:
		item_panel.get_parent().remove_child(item_panel)
		items_container.add_child(item_panel)
	
	var stats: String = """
	Wave reached: %s,
	Enemies slaughtered: %s
						""" % [EntitiesManager.current_wave, EntitiesManager.total_enemies_killed]
	
	stat_label.text = stats

func _on_try_again_pressed():
	GameManager.state = "PLAYING"
	GameManager.change_scene()

func _on_menu_pressed():
	get_tree().paused = false
	GameManager.state = "MENU"
	GameManager.change_scene()
