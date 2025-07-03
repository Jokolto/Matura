class_name RangedEnemy extends Enemy


@onready var weapon_holder = $Weaponholder

var fire_rate_multiplier: float
var attack_range: float
var ranged_damage_multiplier: float

var start_weapon: PackedScene = preload("res://scenes/weapons/guns/gun1.tscn") 
var _current_weapon: Node = null  

func _ready() -> void:
	stats = preload("res://resources/enemies/ranged_enemy.tres")
	super._ready()
	
	fire_rate_multiplier = stats.fire_rate_multiplier
	attack_range = stats.attack_range
	
	if start_weapon != null:
		_current_weapon = start_weapon.instantiate()
		weapon_holder.add_child(_current_weapon)
		_current_weapon.set_projectiles_node(projectiles_node)
	

func _physics_process(_delta: float) -> void:
	
	var dir: Vector2 = Vector2.ZERO
	#print(player)
	
	if is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
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
