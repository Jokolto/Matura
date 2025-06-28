extends Node2D

#var enemy_scene: PackedScene = preload("res://scenes/entities/enemies/enemy.tscn")
@onready var WaveTimer = $WaveTimer
@onready var PauseMenu = $UI/PauseMenu
var rest_time: float = 2.5

func _ready() -> void:
	EntitiesManager.wave_end.connect(_on_wave_end)
	WaveTimer.start(rest_time)
	
	PlayerManager.player.died.connect(EntitiesManager._on_player_death)
	
	EntitiesManager.current_wave = 0
	EntitiesManager.enemies_per_wave = 0
	EntitiesManager.enemies_alive = 0
	# the nodes do it themselves now
	#EntitiesManager.set_entities_node($Entities)
	#ProjectileManager.set_proj_node($Projectiles)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"): # Typically Escape
		PauseMenu.toggle_pause()


func _on_wave_timer_timeout() -> void:
	EntitiesManager.start_wave()
	
func _on_wave_end():
	WaveTimer.start(rest_time)
