extends CharacterBody2D
class_name Enemy

@export var move_speed: float = 100.0
@export var max_health: int = 3
@onready var player: CharacterBody2D = null  # assign this from outside

var enemy_id: int = -1
var health: int = 3


func _ready() -> void:
	generate_id()
	player = get_tree().get_first_node_in_group("Player")
	if not player:
		print("Warning: Enemy has no player reference!")
	health = max_health


func _physics_process(delta: float) -> void:
	#print(player)
	if is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
		

func generate_id():
	if enemy_id == -1:
		enemy_id = EnemyManager.get_next_enemy_id()

	# Generate a name like "Goblin_3" or "Orc_5"
	var type_name = get_name()
	name = "%s_%d" % [type_name, enemy_id]
	
