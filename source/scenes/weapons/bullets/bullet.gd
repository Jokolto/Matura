extends Area2D

@export var speed: float = 600.0
var direction: Vector2 = Vector2.ZERO
var bullet_id = 0
var gun_node: Node = null
var damage: float = 0.0  # assigned by gun

func _ready() -> void:
	generate_id()
	
func _process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.take_damage(damage)
	
	ProjectileManager.proj_amount -= 1
	queue_free()
	

func generate_id():
	if bullet_id == -1:
		bullet_id = ProjectileManager.get_next_proj_id()

	# Generate a name like "Goblin_3" or "Orc_5"
	var type_name = get_name()
	name = "%s_%d" % [type_name, bullet_id]
