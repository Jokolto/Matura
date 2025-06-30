class_name RangedEnemy extends Enemy


@export var attack_range = 1000
@onready var weapon_holder = $Weaponholder
var fire_rate_multiplier = 0.25

var start_weapon: PackedScene = preload("res://scenes/weapons/guns/gun1.tscn") 
var _current_weapon: Node = null

func _ready() -> void:
	move_speed = 100
	max_health = 2
	super._ready()
	if start_weapon != null:
		_current_weapon = start_weapon.instantiate()
		weapon_holder.add_child(_current_weapon)
	

func _physics_process(_delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	var dir: Vector2 = Vector2.ZERO
	#print(player)
	
	if is_instance_valid(player):
		var pos = player.global_position
		dir = (player.global_position - global_position).normalized()	
		
		weapon_holder._aim_weapon(pos)
		if distance_to_player <= attack_range:
			_current_weapon.try_fire(pos)
			
		
		velocity = dir * move_speed
		move_and_slide()
	
	
	if player_inside_contact_range:
		_deal_damage(player)
	
	_update_animation(dir)
