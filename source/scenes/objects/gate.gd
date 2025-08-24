extends Node2D
class_name Gate

@onready var hp_component = $HpComponent
@onready var door_hit_box = $StaticBody2D/CollisionShape2D
@onready var Sprite = $BotomSprite

var ui: Node = null

@export var intact_texture: Texture2D
@export var broken_texture: Texture2D

signal gate_regenerated

var max_hp = 100
var hp_regeneration_per_sec = 20
var hp_timer = 0
var destroyed = false
var hp_is_full = true

func _ready() -> void:
	Sprite.texture = intact_texture
	hp_component.connect("died", _on_died)
	hp_component.max_health = max_hp
	hp_component.current_health = max_hp
	hp_component._update_bar()

func _process(delta: float) -> void:
	hp_is_full = hp_component.current_health >= hp_component.max_health
	if not destroyed and not hp_is_full:
		if hp_timer >= 1:
			hp_timer = 0
			hp_component.heal(hp_regeneration_per_sec)
			hp_is_full= hp_component.current_health >= hp_component.max_health
			if hp_is_full:
				gate_regenerated.emit()
		hp_timer += delta
		
func set_ui(node):
	ui = node	

func take_damage(damage: float):
	Logger.log("Gate took dmg: %s" % [damage], "DEBUG")
	hp_component.take_damage(damage)
	ui.show_damage_ui(damage, global_position)

func _on_died():
	Sprite.texture = broken_texture
	destroyed = true
	door_hit_box.queue_free()
	hp_component.visible = false
