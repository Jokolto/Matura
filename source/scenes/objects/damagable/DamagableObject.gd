extends Node2D
class_name DamagableObject
# Abstract base for destructible/interactive objects

@onready var hp_component = $HpComponent

var ui: Node = null

@export var max_hp: int = 100
@export var hp_regeneration_per_sec: int = 0
@export var intact_texture: Texture2D
@export var broken_texture: Texture2D

signal died
signal regenerated

var destroyed := false
var hp_is_full := true
var hp_timer := 0.0

func _ready() -> void:
	hp_component.connect("died", _on_died)
	hp_component.max_health = max_hp
	hp_component.current_health = max_hp
	_apply_intact_visuals()

func _process(delta: float) -> void:
	hp_is_full = hp_component.current_health >= hp_component.max_health
	if not destroyed and not hp_is_full and hp_regeneration_per_sec > 0:
		if hp_timer >= 1.0:
			hp_timer = 0.0
			hp_component.heal(hp_regeneration_per_sec)
			hp_is_full = hp_component.current_health >= hp_component.max_health
			if hp_is_full:
				regenerated.emit()
		hp_timer += delta

func set_ui(node: Node):
	ui = node

func take_damage(damage: float):
	Logger.log("%s took dmg: %s" % [name, damage], "DEBUG")
	hp_component.take_damage(damage)
	if ui:
		ui.show_damage_ui(damage, global_position)

func _on_died():
	destroyed = true
	_apply_broken_visuals()
	hp_component.visible = false
	died.emit()

# --- Meant to be overridden by child classes ---
func _apply_intact_visuals():
	pass

func _apply_broken_visuals():
	pass
