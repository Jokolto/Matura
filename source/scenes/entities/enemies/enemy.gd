extends CharacterBody2D
class_name Enemy

@export var move_speed: float = 100.0
@export var max_health: int = 3
@onready var player: CharacterBody2D = null  # assign this later
@onready var body_sprite = $AnimatedSprite2D


var enemy_id: int = -1
var health: int = 3
var contact_damage: float = 1
var player_inside_contact_range: bool = false

signal enemy_death

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	#enemy_death.connect(_on_death)
	enemy_death.connect(EntitiesManager._on_enemy_death)
	enemy_death.connect(GameManager.hud._on_enemy_death)
	
	
	generate_id()
	player = PlayerManager.get_player()
	if not player:
		print("Warning: Enemy has no player reference!")
	health = max_health


func _physics_process(_delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	#print(player)
	if is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()
	
	if player_inside_contact_range:
		_deal_damage(player)
	
	_update_animation(dir)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
		enemy_death.emit()
		

func generate_id():
	if enemy_id == -1:
		enemy_id = EntitiesManager.get_next_enemy_id()

	# Generate a name like "Goblin_3" or "Orc_5"
	var type_name = get_name()
	name = "%s_%d" % [type_name, enemy_id]
	

func _update_animation(input_vec: Vector2) -> void:
	# ---- play the correct clip ----
	if input_vec != Vector2.ZERO:
		if body_sprite.animation != "run":
			body_sprite.play("run")
	else:
		if body_sprite.animation != "idle":
			body_sprite.play("idle")
	 #---- face the correct direction ----  // no need, gun aim decides the orientation
	if input_vec.x != 0:
		body_sprite.flip_h = input_vec.x < 0
		

func _deal_damage(body: Node) -> void:
	body.take_damage(contact_damage)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_inside_contact_range = true
		
func _on_body_exited(body: Node) -> void:
	if body is Player:	
		player_inside_contact_range = false
		

#func _on_death():
	#queue_free()
