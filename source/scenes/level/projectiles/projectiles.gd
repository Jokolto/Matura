extends Node
var next_proj_id = 0
var proj_amount = 0
@onready var player_projectile_node = $PlayerProjectiles
@onready var level_node = $".."

func get_next_proj_id() -> int:
	var id = next_proj_id
	next_proj_id += 1
	proj_amount += 1
	return id

func _ready() -> void:
	pass
	
func get_player_projectiles() -> Array:
	return player_projectile_node.get_children()


func get_nearest_player_bullet_to_pos(global_pos) -> Node2D:
	var bullets = get_player_projectiles()
	var nearest = null
	var nearest_dist = INF

	for bullet in bullets:
		var dist = global_pos.distance_to(bullet.global_position)
		if dist < nearest_dist:
			nearest = bullet
			nearest_dist = dist

	return nearest
