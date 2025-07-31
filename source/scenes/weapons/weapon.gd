extends Node2D
class_name Weapon

enum WeaponType { MELEE, RANGED }
@export var stats: Resource
var holder: CharacterBody2D = null
var _cooldown: float = 0.0
var automatic: bool = true
var weapon_type: WeaponType = WeaponType.MELEE  # Default, overridden by child
var is_lying_on_floor: bool = false

# for enemies
var stored_state: String = ""
var stored_action: String = "use_weapon"
var projectiles_node: Node = null

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta

func get_holder():
	return get_parent().get_parent()

func is_ready() -> bool:
	return _cooldown <= 0.0

func trigger_cooldown(rate_multiplier: float = 1.0) -> void:
	if stats.fire_rate:
		_cooldown = 1.0 / (stats.fire_rate * rate_multiplier)

func store_state(state, action):
	stored_state = state
	stored_action = action

func import_res_stats(res: Resource) -> void:
	stats = res

# Unified interface method
func use_weapon(direction_or_target_pos: Vector2) -> void:
	# To be overridden in child classes
	pass

func on_pickup(player):
	Logger.log("Player picked up weapon", "DEBUG")
	player._equip_weapon(stats)
	queue_free()  # Remove from world

func set_projectiles_node(node: Node) -> void:
	projectiles_node = node
