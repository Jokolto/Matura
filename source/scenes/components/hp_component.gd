extends Node

signal health_changed(current, max)
signal died

@export var max_health := 100
@export var auto_hide := true
@onready var current_health := max_health
@onready var bar := $MarginContainer/HealthBar
@onready var hp_label = $MarginContainer/Label
var use_label = false
var dead = false # in case for some reason the hp component parent is not freed 

func _ready():
	_update_bar()

func take_damage(amount: float):
	if dead:
		bar.visible = false
		return
	current_health = max(current_health - amount, 0)
	_update_bar()
	emit_signal("health_changed", current_health, max_health)
	if current_health == 0:
		dead = true
		emit_signal("died")

func heal(amount: float):
	current_health = min(current_health + amount, max_health)
	_update_bar()
	emit_signal("health_changed", current_health, max_health)

func _update_bar():
	bar.value = current_health
	bar.max_value = max_health
	hp_label.text = "%d / %d" % [current_health, max_health]
	hp_label.visible = (not auto_hide or current_health < max_health) and use_label
	bar.visible = not auto_hide or current_health < max_health
