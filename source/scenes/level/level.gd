extends Node2D

@onready var WaveTimer = $WaveTimer

# UI
@onready var UI = $UI
@onready var Upgradepanel = $UI/UpgradePanel
@onready var PauseMenu = $UI/PauseMenu
@onready var hud = $UI/HUD
@onready var tutorial = $UI/TutorialPanel


@onready var projectiles_node: Node = $Projectiles
@onready var entities_node: Node2D = $Entities
@onready var enemies_node: Node = $Entities/Enemies
@onready var player: Player = $Entities/Player
@onready var spawners_node: Node2D = $Objects/Spawners
@onready var gates: Node2D = $Objects/Gates
@onready var world_boundary: Area2D = $Objects/WorldBoundary

@onready var pickups_node: Node2D = $Objects/Pickups
@onready var ItemManager = $ItemManager


# starting weapons of player for experiments
var gun_res: Resource = preload("res://resources/weapons/guns/handgun.tres")
var melee_res: Resource = preload("res://resources/weapons/melee/sword.tres")



var cursor_texture = preload("res://assets/sprites/v1.1 dungeon crawler 16X16 pixel pack/ui (new)/crosshair_1.png")
var play_time: float = 0.0
signal pause
signal rest_time_end

func _ready() -> void:
	play_time = 0.0
	pause.connect(PauseMenu._on_pause)
	rest_time_end.connect(Upgradepanel._on_rest_time_end)
	EntitiesManager.wave_end.connect(_on_wave_end)
	
	Upgradepanel.upgrade_selected.connect(_on_upgrade_selected)
	EntitiesManager.wave_end.connect(player._on_wave_end)
	
	player.damaged.connect(hud._on_player_damaged)
	player.healed.connect(hud._on_player_healed)
	player.died.connect(hud._on_player_death)
	player.died.connect(EntitiesManager._on_player_death)
	player.died.connect(GameManager._on_player_death)
	player.weapon_equipped.connect(hud._on_player_weapon_equiped)
	player.shot.connect(hud._on_player_shoot)
	player.weapon_nearby.connect(tutorial._on_player_weapon_nearby)

	world_boundary.won.connect(_on_win)
	world_boundary.won.connect(hud._on_win)
	world_boundary.won.connect(GameManager._on_win)
	
	
	
	EntitiesManager.wave_active = false
	EntitiesManager.current_wave = 0
	EntitiesManager.enemies_per_wave = 1
	EntitiesManager.enemies_alive = 0
	EntitiesManager.enemies_spawned = 0
	EntitiesManager.total_enemies_killed = 0
	EntitiesManager.enemy_speed_mul = 1 
	EntitiesManager.enemy_hp_mul = 1
	EntitiesManager.enemy_dmg_mul = 1
	
	for gate: Gate in gates.get_children():
		gate.regenerated.connect(tutorial._on_gate_regen_first_time)
		gate.set_ui(UI)
	
	
	# passing player reference
	for node in [ItemManager, hud, Upgradepanel, spawners_node]:
		node.set_player(player)
	
	# passing itemmanager reference
	for node in [Upgradepanel, hud, spawners_node]:
		node.set_item_manager(ItemManager)
	
	# passing projectiles_node reference 
	spawners_node.set_projectiles_node(projectiles_node)
	player.set_projectiles_node(projectiles_node)
	
	# passing ui node
	spawners_node.set_ui(UI)
	
	# pickup
	spawners_node.set_pickups_node(pickups_node)
	player.set_pickups_node(pickups_node)
	
	spawners_node.set_enemies_node(enemies_node)
	player.set_enemies_node(enemies_node)
		
	set_default_nodes()
	tutorial.show_tutorial_piece("move")

func _process(delta: float) -> void:
	var start_condition = (len(GameManager.shown_tutorials) == GameManager.tutorials_amount or not GameManager.tutorial_enabled) \
		and not EntitiesManager.wave_active and EntitiesManager.current_wave == 0
	if start_condition:
		EntitiesManager.start_wave()
	play_time += delta

func set_default_nodes():
	hud.set_health(player.hp, player.max_hp)
	if GlobalConfig.player_starts_with_weapon:
		player._equip_weapon(gun_res)
	

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"): # Typically Escape
		GameManager.toggle_pause()
		pause.emit()
	if event.is_action_pressed("kill_all"):
		if GlobalConfig.DEBBUGGING:
			enemies_node.kill_all()
	
func _on_wave_end(_fitness):
	WaveTimer.start(1.5)


func _on_wave_timer_timeout() -> void:
	rest_time_end.emit()

func _on_upgrade_selected():
	
	EntitiesManager.start_wave()

func _on_win():
	EntitiesManager.won_time_sec = play_time
