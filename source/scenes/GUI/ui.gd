extends Node
@onready var indicators_node = $Indicators
@export var dmg_ui_scene = preload("res://scenes/GUI/damage_indicator.tscn")

func show_damage_ui(damage_amount: float, position: Vector2):
	var dmg_label = dmg_ui_scene.instantiate()
	dmg_label.text = str(round(damage_amount))
	indicators_node.add_child(dmg_label)  # projectiles node, why not.
	dmg_label.global_position = position
