extends Node
@onready var indicators_node = $Indicators
@export var dmg_ui_scene = preload("res://scenes/GUI/damage_indicator.tscn")

func show_damage_ui(damage_amount: float, position: Vector2, dodge: bool = false):
	var dmg_label: Label = dmg_ui_scene.instantiate()
	var label_settings = LabelSettings.new()
	label_settings.font_color = Color.RED
	label_settings.font_size = 32
	label_settings.outline_color = Color.BLACK
	label_settings.outline_size = 6
	if damage_amount < 0:
		label_settings.font_color = Color.GREEN
		
	dmg_label.text = ("%.1f" % abs(damage_amount)).rstrip("0").rstrip(".")
	
	if dodge:
		dmg_label.text = 'Dodged'
		label_settings.font_color = Color.GRAY
	
	dmg_label.label_settings = label_settings
	indicators_node.add_child(dmg_label)  # projectiles node, why not.
	dmg_label.global_position = position
