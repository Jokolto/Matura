extends CanvasLayer


@onready var health_bar: ProgressBar = $MarginContainer/StatusVBoxContainer/MarginContainer/HealthBar
@onready var health_label = $MarginContainer/StatusVBoxContainer/MarginContainer/Label
@onready var enemies_bar: ProgressBar = $MarginContainer/EnemiesVBoxContainer/MarginContainer/EnemiesCountBar
@onready var enemies_label = $MarginContainer/EnemiesVBoxContainer/MarginContainer/Label
@onready var wave_label = $MarginContainer/EnemiesVBoxContainer/Label
@onready var enemies_bar_container = $MarginContainer/EnemiesVBoxContainer/MarginContainer
@onready var player = PlayerManager.get_player()

func _ready() -> void:
	EntitiesManager.wave_start.connect(_on_wave_start)
	EntitiesManager.wave_end.connect(_on_wave_end)
	player.damaged.connect(_on_player_damaged)
	GameManager._set_hud(self)
	
	wave_label.text = "Rest time"
	enemies_bar_container.visible = false
	
	set_health(player.hp, player.max_hp)
	
	
func set_health(value: int, max_value: int) -> void:
	health_bar.max_value = max_value
	health_bar.value = value
	health_label.text = "%d / %d" % [value, max_value]

func set_enemy_hud(value: int, max_value: int) -> void:
	enemies_bar.max_value = max_value
	enemies_bar.value = value
	enemies_label.text = "Enemies left: " + "%d / %d" % [value, max_value]
	
	
func _on_player_damaged(_damage):
	set_health(player.hp, player.max_hp)

func _on_enemy_death():
	set_enemy_hud(EntitiesManager.enemies_alive, EntitiesManager.enemies_per_wave)
	
func _on_wave_start():
	enemies_bar_container.visible = true
	wave_label.text = "Wave: " + str(EntitiesManager.current_wave)

func _on_wave_end():
	enemies_bar_container.visible = false
	wave_label.text = "Rest time"

func _on_enemy_spawned():
	set_enemy_hud(EntitiesManager.enemies_alive, EntitiesManager.enemies_per_wave)
	
func _on_upgrade_selected():
	set_health(player.hp, player.max_hp)
