extends DamagableObject
class_name Gate

@onready var door_hit_box = $StaticBody2D/CollisionShape2D
@onready var Sprite = $BotomSprite

func _apply_intact_visuals():
	Sprite.texture = intact_texture

func _apply_broken_visuals():
	Sprite.texture = broken_texture
	door_hit_box.queue_free()
