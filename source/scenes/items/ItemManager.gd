extends Node

var player: Node = null
var held_items: Dictionary = {}


func set_player(player_scene):
	player = player_scene

func apply_item(item: ItemData):
	
	match item.effect:
		"fire_rate_up":
			player.fire_rate_multiplier += item.effect_value
		"damage_up":
			player.damage_flat_boost += item.effect_value
		"max_hp":
			player.max_hp += item.effect_value
		"move_speed":
			player.move_speed += item.effect_value
		"fire_rate":
			player.fire_rate += item.effect_value
		"damage_multiply":
			player.damage_multiplier += item.effect_value
		_:
			print("Unknown upgrade type: ", item.effect)
		


func _on_item_selected(item):
	apply_item(item)
	if held_items.has(item):
		held_items[item] += 1
	else:
		held_items[item] = 1
	
