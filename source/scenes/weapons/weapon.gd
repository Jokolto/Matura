extends Node2D
class_name Weapon

enum WeaponType { MELEE, RANGED }
@export var stats: Resource
var holder: CharacterBody2D = null
var _cooldown: float = 0.0
var automatic: bool = true
var weapon_type: WeaponType = WeaponType.MELEE  # Default, overridden by child


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

func import_res_stats(res: Resource) -> void:
	stats = res

# Unified interface method
func use_weapon(direction_or_target_pos: Vector2) -> void:
	# To be overridden in child classes
	pass
