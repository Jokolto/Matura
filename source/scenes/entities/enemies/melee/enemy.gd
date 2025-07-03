class_name Enemy extends CharacterBody2D

@export var stats: Resource = preload("res://resources/enemies/general_enemy.tres")


@onready var body_sprite = $AnimatedSprite2D


var player: CharacterBody2D = null  # assigned from spawner
var projectiles_node: Node = null # assigned from spawner

var move_speed: float 
var max_health: float 
var health: float
var contact_damage: float

var player_inside_contact_range: bool = false
var enemy_id: int = -1

signal enemy_death

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	#enemy_death.connect(_on_death)
	enemy_death.connect(EntitiesManager._on_enemy_death)
	enemy_death.connect(GameManager.hud._on_enemy_death)
	
	
	generate_id()
	
	move_speed = stats.move_speed
	max_health = stats.max_health 
	contact_damage = stats.contact_damage
	health = max_health
	
	


func _physics_process(_delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	if is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()
	if player_inside_contact_range:
		_deal_damage(player)
	
	_update_animation(dir)


func set_player(player_instance):
	player = player_instance


func set_projectiles_node(node: Node):
	projectiles_node = node

func take_damage(amount: float) -> void:
	if health <= 0:   # multiple bullets could kill enemies multiple times without this
		return 
		
	health -= amount
	if health <= 0:
		enemy_death.emit()
		queue_free()
		
		

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
