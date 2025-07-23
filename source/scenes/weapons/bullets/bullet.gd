extends Area2D
class_name Bullet

var direction: Vector2 = Vector2.ZERO
var bullet_id = 0
var shot_at_pos: Vector2 = Vector2.ZERO 

var damage: float # assigned by gun
var speed: float # assigned by gun
var shooting_range: float # assigned by gun
var piercing: int

var shooter: CharacterBody2D = null # assigned by gun
enum ShooterType { PLAYER, ENEMY }
var shooter_type: ShooterType

var projectiles_node: Node = null  # assigned by gun
var gun_node: Node = null  # assigned by gun


var friendly_fire = false
var hit_entities = []


func _ready() -> void:
	match shooter:
		Player:
			shooter_type = ShooterType.PLAYER
		Enemy:
			shooter_type = ShooterType.ENEMY
			
	shot_at_pos = global_position
	generate_id()

func _process(delta: float) -> void:
	position += direction * speed * delta
	
	if global_position.distance_to(shot_at_pos) >= shooting_range:
		projectiles_node.proj_amount -= 1
		queue_free()
	

# quite a bad handling, but i don't care
func _on_body_entered(body: Node2D) -> void:
	if body != shooter:    # ensure no self colision, can cause a one frame bug if entity is killed right as it shoots
		if (body is CharacterBody2D):    # ensure colision with entities
			if (shooter_type == ShooterType.PLAYER or body is Player):   # either player hitting enemy, or enemy hitting player
				if not body in hit_entities:
					hit_entities.append(body)
					body.take_damage(damage)
					if piercing >= 1:
						piercing -= 1
						return
					projectiles_node.proj_amount -= 1
					queue_free()
			elif (body is Enemy and shooter_type == ShooterType.ENEMY and friendly_fire):     # enemy hitting enemy
				body.take_damage(damage)
		elif body.get_parent() is Gate:
			body.get_parent().take_damage(damage)
		
		# colision with some other object, e.g. wall
		
		projectiles_node.proj_amount -= 1
		queue_free()
		
		
	

func generate_id():
	if bullet_id == -1:
		bullet_id = projectiles_node.get_next_proj_id()

	# Generate a name like 
	var type_name = get_name()
	name = str(shooter) + "%s_%d" % [type_name, bullet_id]
