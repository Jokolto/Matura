extends Node2D
class_name Pickup

@onready var hitbox: Area2D = $Area2D
@onready var hitbox_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sprite = $Sprite2D


func on_pickup(_player):
	pass
	# to be overriden
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.nearby_pickups.append(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		body.nearby_pickups.erase(self)
