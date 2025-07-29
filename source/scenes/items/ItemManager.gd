extends Node

var player: Player = null
var held_items: Dictionary = {}
var item_pool: Array[ItemData] = []
var gun_pool: Array[GunData] = []

@export var items_resources_paths: ResourceGroup = preload("res://resources/items.tres")
@export var guns_resources_paths: ResourceGroup = preload("res://resources/weapons/guns.tres")
@export var melee_resources_paths: ResourceGroup

var rarity_distribution: Dictionary = {1 : 0.6,  2 : 0.25,  3 : 0.1, 4 : 0.05} 
var gun_wave_n = -1 # after this wave player gets a gun

func _ready() -> void:
	 
	items_resources_paths.load_all_into(item_pool)
	guns_resources_paths.load_all_into(gun_pool)
	

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
			player.hp += item.effect_value
		"move_speed":
			player.move_speed += item.effect_value
		"fire_rate":
			player.fire_rate += item.effect_value
		"damage_multiply":
			player.damage_multiplier += item.effect_value
		_:
			print("Unknown upgrade type: ", item.effect)
		

func get_random_items_from_pool(pool: Array, item_amount: int, rarity_distribution_for_items: Dictionary = {}, minus_pool=[]) -> Array:
	var options = pool
	var chosen_items = minus_pool
	

	if not rarity_distribution_for_items:  # not weighted random - used for guns
		options = options.filter(func(x): return not minus_pool.has(x))  # to remove held guns from options
		options.shuffle()
		return options.slice(0, item_amount)
		
	for i in range(item_amount): # weighted random - used for items
		chosen_items.append(get_random_item(options, chosen_items, rarity_distribution_for_items)) 

	return chosen_items
	
func get_random_item(options: Array, chosen_already: Array, rarity_distribution_for_items: Dictionary = {}) -> Resource:
	var roll = randf()  # random float between 0.0 and 1.0
	var cumulative = 0.0
	for item in options:
		if item in chosen_already:
			continue
			
		cumulative += rarity_distribution_for_items[item.rarity]
		if roll <= cumulative:
			return item
	return null # should not go here, if rarities sum is 1

func get_random_items(items_amount):
	return get_random_items_from_pool(item_pool, items_amount, rarity_distribution)

func get_random_guns(guns_amount, held_guns):
	return get_random_items_from_pool(gun_pool, guns_amount, {}, held_guns)

func _on_item_selected(item, is_gun_update):
	if is_gun_update:
		player._equip_weapon(item)
		return
		
	apply_item(item)
	if held_items.has(item):
		held_items[item] += 1
	else:
		held_items[item] = 1
	
