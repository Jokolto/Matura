extends CanvasLayer

@onready var upgrades_buttons = $Panel/HBoxContainer
@onready var buttons = upgrades_buttons.get_children()
@onready var blocker = $Panel/MouseBlocker
var rarity_namings: Dictionary = {1 : "common",  2 : "uncommon",  3 : "rare", 4 : "legendary"} 
var input_ready = false
var ItemManager = null
var player: Player = null

var gun_wave = false

func _ready():
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	EntitiesManager.wave_end.connect(_on_wave_end)
	for button in buttons:
		button.pressed.connect(_on_upgrade_selected)
		
	hide()

func set_player(player_instance: Player):
	player = player_instance

func set_item_manager(manager):
	ItemManager = manager

func show_upgrade_panel():
	gun_wave = EntitiesManager.current_wave == ItemManager.gun_wave_n
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused
	var to_choose_amount = len(buttons) # 3 default
	var options: Array
	if gun_wave:  
		options = ItemManager.get_random_guns(to_choose_amount, [player.current_gun_res]) 
		
	else:
		options = ItemManager.get_random_items(to_choose_amount)
		
	# configuring the buttons and connecting the signals.
	for i in range(to_choose_amount):
		var button: Button = buttons[i]
		var first_click = not button.pressed.is_connected(ItemManager._on_item_selected)
		var item = options[i]
		var icon: Texture2D
		
		if gun_wave:
			var gun_sprite = item["sprite"]
			#gun_sprite.rotation_degrees = -60    # rotation for better display
			icon = gun_sprite
		else:		
			icon = item["icon"]
			set_button_rarity_style(button, rarity_namings[item["rarity"]])
	
		button.text = item["name"] + "\n" + item["description"]
		button.icon = icon
		
		
		if not first_click:  
			button.pressed.disconnect(ItemManager._on_item_selected)
			button.pressed.disconnect(GameManager.hud._on_upgrade_selected)  # redisconnecting, connecting just so that order stays
			
		button.pressed.connect(ItemManager._on_item_selected.bind(item, gun_wave))
		button.pressed.connect(GameManager.hud._on_upgrade_selected.bind(item))

func set_button_rarity_style(button: Button, rarity: String) -> void:
	var border_color: Color

	match rarity:
		"common":
			border_color = Color.GRAY
		"uncommon":
			border_color = Color.LIME_GREEN
		"rare":
			border_color = Color.DODGER_BLUE
		"epic":
			border_color = Color.MEDIUM_PURPLE
		"legendary":
			border_color = Color.ORANGE
		_:
			border_color = Color.DIM_GRAY

	var stylebox := StyleBoxFlat.new()
	for side in ["left", "top", "right", "bottom"]:
		stylebox.set("border_width_" + side, 1)
		
	stylebox.border_color = border_color
	stylebox.bg_color = Color.from_hsv(94, 0.06, 0.19) # Dark gray

	button.add_theme_stylebox_override("normal", stylebox)
	#button.add_theme_stylebox_override("hover", stylebox)

func _on_wave_end(_fitness_dict):
	blocker.visible = true
	show_upgrade_panel()
	await get_tree().create_timer(0.7).timeout
	blocker.visible = false
	

func _on_upgrade_selected():
	visible = false
	get_tree().paused = false
	
