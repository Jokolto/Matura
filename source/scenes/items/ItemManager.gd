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
			player.weapons_automatic_override = true
		"damage_up":
			player.damage_flat_boost += item.effect_value
		"max_hp":
			player.max_hp += player.max_hp * item.effect_value
			player.hp += player.hp * item.effect_value
		"move_speed":
			player.move_speed += player.move_speed * item.effect_value
		"damage_multiply":
			player.damage_multiplier += item.effect_value
		"crit_chance":
			player.crit_chance += item.effect_value
		"clock":
			EntitiesManager.enemy_speed_mul -= item.effect_value
		"contact_damage":
			player.contact_damage += item.effect_value
		_:
			print("Unknown upgrade type: ", item.effect)
		

func get_random_items_from_pool(pool: Array, item_amount: int, rarity_distribution_for_items: Dictionary = {}, minus_pool=[]) -> Array:
	var options = pool
	var chosen_items = []
	

	if not rarity_distribution_for_items:  # not weighted random - used for guns
		options = options.filter(func(x): return not minus_pool.has(x))  # to remove held guns from options
		options.shuffle()
		return options.slice(0, item_amount)
		
	for i in range(item_amount): # weighted random - used for items
		chosen_items.append(get_random_item(options, chosen_items, rarity_distribution_for_items)) 

	return chosen_items
	
func get_random_item(options: Array, chosen_already: Array, rarity_distribution_for_items: Dictionary = {}) -> Resource:
	# Step 1: Filter out already chosen items
	var available_items = []
	for item in options:
		if item not in chosen_already:
			available_items.append(item)

	# Step 2: Group items by rarity
	var rarity_groups = {}
	for item in available_items:
		var r = item.rarity
		if not rarity_groups.has(r):
			rarity_groups[r] = []
		rarity_groups[r].append(item)

	# Step 3: Choose a rarity based on distribution
	var roll = randf()
	var cumulative = 0.0
	var chosen_rarity = 1
	for r in rarity_distribution_for_items.keys():
		cumulative += rarity_distribution_for_items[r]
		if roll <= cumulative:
			chosen_rarity = r
			break
	
	# Step 5: Return random item from selected rarity group
	var group = rarity_groups.get(chosen_rarity, [])
	
	while len(group) < 1:
		chosen_rarity -= 1
		group = rarity_groups.get(chosen_rarity, [])
	return group[randi() % group.size()]


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
	
