extends CanvasLayer

@onready var upgrades_buttons = $Panel/VBoxContainer
@onready var buttons = upgrades_buttons.get_children()

func _ready():
	EntitiesManager.wave_end.connect(_on_wave_end)
	for button in buttons:
		button.pressed.connect(_on_upgrade_selected)
		
	hide()

func show_upgrade_panel():
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused
	
	var options = EntitiesManager.upgrades.duplicate()
	options.shuffle()
	options = options.slice(0, len(buttons))

	
	for i in range(len(buttons)):
		var button: Button = buttons[i]
		var first_click = not button.pressed.is_connected(EntitiesManager._on_upgrade_selected)
		var upgrade = options[i]
		button.text = upgrade["name"]
		
		if not first_click:  
			button.pressed.disconnect(EntitiesManager._on_upgrade_selected)
			button.pressed.disconnect(GameManager.hud._on_upgrade_selected)  # redisconnecting, connecting just so that order stays
			
		button.pressed.connect(EntitiesManager._on_upgrade_selected.bind(upgrade))
		button.pressed.connect(GameManager.hud._on_upgrade_selected)
		


func _on_wave_end():
	show_upgrade_panel()

func _on_upgrade_selected():
	visible = false
	get_tree().paused = false
	
