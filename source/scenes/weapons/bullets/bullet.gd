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

var hit_entities = []

# enemy specific
var hit_player = false
var friendly_fire = false
var shot_at_state = ""
var stored_action = "use_weapon"


func _ready() -> void: 
	# match does not work with types in gdscript, hence if elif...
	if shooter is Player:
		shooter_type = ShooterType.PLAYER
	elif shooter is Enemy:
		shooter_type = ShooterType.ENEMY
	elif shooter is RangedEnemy:
		shooter_type = ShooterType.ENEMY
	else:
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
	hit_player = false
	hit_entities = []
	if body == shooter:   
		return  # ensure no self colision
		
	if (body is CharacterBody2D):    # colision with entities
		if (shooter_type == ShooterType.PLAYER):   # player hitting enemy
			if not body in hit_entities:
				hit_entities.append(body)
				body.take_damage(damage)
				if piercing >= 1:
					piercing -= 1
					return
				projectiles_node.proj_amount -= 1
				queue_free()
		elif shooter_type == ShooterType.ENEMY: # enemy hitting player or another enemy
			if body is Player:
				body.take_damage(damage)
				hit_player = true
				
			if body is Enemy and friendly_fire: # enemy hitting enemy
				body.take_damage(damage)
			
	elif body.get_parent() is Gate:
		body.get_parent().take_damage(damage)
	
	if is_instance_valid(shooter):
		if hit_player:
			if shot_at_state:
				shooter.add_reward_event("HIT_PLAYER", shot_at_state, stored_action)
		else:
			shooter.add_reward_event("MISSED", shot_at_state, stored_action)
	
	projectiles_node.proj_amount -= 1
	queue_free()
	
		
	

func generate_id():
	if bullet_id == -1:
		bullet_id = projectiles_node.get_next_proj_id()

	# Generate a name like 
	var type_name = get_name()
	name = str(shooter) + "%s_%d" % [type_name, bullet_id]
