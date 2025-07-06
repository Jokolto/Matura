extends CanvasLayer

@onready var upgrades_buttons = $Panel/HBoxContainer
@onready var buttons = upgrades_buttons.get_children()
@onready var blocker = $Panel/MouseBlocker
var items_pool = []
var input_ready = false
var ItemManager = null

func _ready():
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	items_pool = load_all_items()
	EntitiesManager.wave_end.connect(_on_wave_end)
	for button in buttons:
		button.pressed.connect(_on_upgrade_selected)
		
	hide()

func set_item_manager(manager):
	ItemManager = manager

func show_upgrade_panel():
	
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused
	
	var options = items_pool
	options.shuffle()
	options = options.slice(0, len(buttons))

	
	for i in range(len(buttons)):
		var button: Button = buttons[i]
		var first_click = not button.pressed.is_connected(ItemManager._on_item_selected)
		var item = options[i]
		button.text = item["name"] + "\n" + item["description"]
		button.icon = item["icon"]
		
		if not first_click:  
			button.pressed.disconnect(ItemManager._on_item_selected)
			button.pressed.disconnect(GameManager.hud._on_upgrade_selected)  # redisconnecting, connecting just so that order stays
			
		button.pressed.connect(ItemManager._on_item_selected.bind(item))
		button.pressed.connect(GameManager.hud._on_upgrade_selected.bind(item))
		
	
	
func load_all_items() -> Array:
	var item_list = []
	var path_to_items = "res://resources/items/"
	var dir = DirAccess.open(path_to_items)
	for file in dir.get_files():
		if file.ends_with(".tres"):
			var item = load(path_to_items + file)
			item_list.append(item)
			
	return item_list

func _on_wave_end():
	blocker.visible = true
	show_upgrade_panel()
	await get_tree().create_timer(0.7).timeout
	blocker.visible = false
	

func _on_upgrade_selected():
	visible = false
	get_tree().paused = false
	
