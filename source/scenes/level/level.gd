extends Node2D

#var enemy_scene: PackedScene = preload("res://scenes/entities/enemies/enemy.tscn")
@onready var WaveTimer = $WaveTimer

# UI
@onready var Upgradepanel = $UI/UpgradePanel
@onready var PauseMenu = $UI/PauseMenu
@onready var hud = $UI/HUD

@onready var projectiles_node: Node = $Projectiles
@onready var entities_node: Node = $Entities
@onready var player: Player = $Entities/Player
@onready var spawners_node: Node = $Spawners

@onready var ItemManager = $ItemManager

var rest_time: float = 2.5

func _ready() -> void:
	
	EntitiesManager.wave_end.connect(_on_wave_end)
	WaveTimer.start(rest_time)
	
	player.damaged.connect(hud._on_player_damaged)
	player.died.connect(EntitiesManager._on_player_death)
	player.died.connect(GameManager._on_player_death)
	player.gun_equiped.connect(hud._on_player_gun_equiped)
	
	EntitiesManager.wave_active = false
	EntitiesManager.current_wave = 0
	EntitiesManager.enemies_per_wave = 0
	EntitiesManager.enemies_alive = 0
	EntitiesManager.enemies_spawned = 0
	
	
	# passing player reference
	for node in [ItemManager, hud, spawners_node]:
		node.set_player(player)
	
	# passing itemmanager reference
	Upgradepanel.set_item_manager(ItemManager)
	
	# passing projectiles_node reference 
	spawners_node.set_projectiles_node(projectiles_node)
	
	set_default_nodes()
	

func set_default_nodes():
	player.set_projectiles_node(projectiles_node)
	player.equip_gun()
	
	hud.set_health(player.hp, player.max_hp)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"): # Typically Escape
		PauseMenu.toggle_pause()


func _on_wave_timer_timeout() -> void:
	EntitiesManager.start_wave()
	
func _on_wave_end():
	WaveTimer.start(rest_time)
