extends CharacterBody2D
class_name Enemy

@export var move_speed: float = 100.0
@export var max_health: int = 3
@onready var player: CharacterBody2D = null  # assign this later


var enemy_id: int = -1
var health: int = 3
var contact_damage: float = 1
var player_inside_contact_range: bool = false

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	generate_id()
	player = PlayerManager.get_player()
	if not player:
		print("Warning: Enemy has no player reference!")
	health = max_health


func _physics_process(_delta: float) -> void:
	#print(player)
	if is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()
	
	if player_inside_contact_range:
		_deal_damage(player)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
		

func generate_id():
	if enemy_id == -1:
		enemy_id = EntitiesManager.get_next_enemy_id()

	# Generate a name like "Goblin_3" or "Orc_5"
	var type_name = get_name()
	name = "%s_%d" % [type_name, enemy_id]
	
func _deal_damage(body: Node) -> void:
	body.take_damage(contact_damage)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_inside_contact_range = true
		
func _on_body_exited(body: Node) -> void:
	if body is Player:	
		player_inside_contact_range = false
		
