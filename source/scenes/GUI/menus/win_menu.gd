extends Control

@onready var play_again_button: TextureButton = $Panel/Buttons/PlayButton
@onready var credits_button: TextureButton = $Panel/Buttons/CreditsButton
@onready var menu_button: TextureButton = $Panel/Buttons/MenuButton
@onready var items_grid_container = $Panel/ItemsContainer/ItemsGridContainer
@onready var stat_label = $Panel/statsvcontainer/statLabel

func _ready():
	var item_panels = GameManager.stored_item_panels
	play_again_button.pressed.connect(_on_play_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	for item_panel: Panel in item_panels:
		item_panel.get_parent().remove_child(item_panel)
		items_grid_container.add_child(item_panel)
	
	var stats: String = """
	Wave reached: %s
	Enemies slaughtered: %s
						""" % [EntitiesManager.current_wave, EntitiesManager.total_enemies_killed]
	
	stat_label.text = stats


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
