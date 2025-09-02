class_name RangedEnemy extends Enemy
# RangedEnemy is not quite a good name, but due to lazyness of renaming a lot of stuff, it is kept that way. 
# better name would be EnemywithWeapon or something similar

@onready var weapon_holder = $Weaponholder

var fire_rate_multiplier: float = 1
var attack_range: float
var ranged_damage_multiplier: float = 1

#var start_weapon: PackedScene = preload("res://scenes/weapons/guns/gun1.tscn") 
var start_weapon: PackedScene = preload("res://scenes/weapons/melee/melee_weapon.tscn") 
var default_weapon_res: Resource = preload("res://resources/weapons/melee/stick.tres")


func _ready() -> void:
	stats = preload("res://resources/enemies/ranged_enemy.tres")
	super._ready()
	
	fire_rate_multiplier = stats.fire_rate_multiplier
	attack_range = stats.attack_range
	
	if default_weapon_res != null:
		equip_weapon()


func _physics_process(_delta: float) -> void:
	if is_instance_valid(player):
		var pos = player.global_position
		dir = (player.global_position - global_position).normalized()	
		weapon_holder._aim_weapon(pos)
			
	super._process(_delta)
	
	
	if player_inside_contact_range:
		_deal_damage(player)
	
	_update_animation(dir)


func equip_weapon(new_weapon_res = default_weapon_res): # very similar to same name method of player, maybe i should do weapon component later to reduce duplication of code.
	if weapon_instance:
		weapon_instance.queue_free()
	
	var scene = load(new_weapon_res.scene_path) as PackedScene
	weapon_instance = scene.instantiate() as Weapon
	
	weapon_instance.import_res_stats(new_weapon_res)

	weapon_instance.set_projectiles_node(projectiles_node)
	weapon_holder.add_child(weapon_instance)
	enemy_type = weapon_instance.weapon_type
	var sprite = weapon_instance.get_node("Sprite2D") as Sprite2D
	sprite.texture = new_weapon_res.sprite
		

		
