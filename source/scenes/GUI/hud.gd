extends CanvasLayer


@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var player = PlayerManager.get_player()

func _ready() -> void:
	#GameManager.set_hud(self)
	player.damaged.connect(_on_player_damaged)
	set_health(player.hp, player.max_hp)
	
	
func set_health(value: int, max_value: int) -> void:
	health_bar.max_value = max_value
	health_bar.value = value


func _on_player_damaged(_damage):
	set_health(player.hp, player.max_hp)
