extends CanvasLayer


@onready var health_bar: ProgressBar = $MarginContainer/StatusVBoxContainer/MarginContainer/HealthBar
@onready var health_label = $MarginContainer/StatusVBoxContainer/MarginContainer/Label
@onready var enemies_bar: ProgressBar = $MarginContainer/EnemiesVBoxContainer/MarginContainer/EnemiesCountBar
@onready var enemies_label = $MarginContainer/EnemiesVBoxContainer/MarginContainer/Label
@onready var wave_label = $MarginContainer/EnemiesVBoxContainer/Label
@onready var enemies_bar_container = $MarginContainer/EnemiesVBoxContainer/MarginContainer

@onready var gun_container = $GunMarginContainer/Panel/TextureRect

@onready var item_container = $ItemsContainer/ItemsHBoxContainer

var player = null # set by level node
var ItemManager = null # set by level node

var item_panels: Array = []
var ItemPanel: PackedScene = preload("res://scenes/GUI/hud/item_panel.tscn")


func _ready() -> void:
	EntitiesManager.wave_start.connect(_on_wave_start)
	EntitiesManager.wave_end.connect(_on_wave_end)
	
	GameManager._set_hud(self)
	
	wave_label.text = "Rest time"
	enemies_bar_container.visible = false
	
func set_item_manager(manager):
	ItemManager = manager

	
func set_health(value: int, max_value: int) -> void:
	health_bar.max_value = max_value
	health_bar.value = value
	health_label.text = "%d / %d" % [value, max_value]

func set_enemy_hud(value: int, max_value: int) -> void:
	enemies_bar.max_value = max_value
	enemies_bar.value = value
	enemies_label.text = "Enemies left: " + "%d / %d" % [value, max_value]
	
func set_player(player_scene):
	player = player_scene

func _on_player_damaged(_damage):
	set_health(player.hp, player.max_hp)

func _on_enemy_death(_enemy_q_table):
	set_enemy_hud(EntitiesManager.enemies_alive, EntitiesManager.enemies_per_wave)
	
func _on_wave_start():
	enemies_bar_container.visible = true
	wave_label.text = "Wave: " + str(EntitiesManager.current_wave)

func _on_wave_end():
	enemies_bar_container.visible = false
	wave_label.text = "Rest time"

func _on_enemy_spawned():
	set_enemy_hud(EntitiesManager.enemies_alive, EntitiesManager.enemies_per_wave)
	
func _on_upgrade_selected(item):
	set_health(player.hp, player.max_hp)
	if ItemManager.held_items.has(item):    # checking if item was registered successfully
		for item_panel in item_container.get_children():   # checking if item is already there 
			if item_panel.item_name == item["name"]:
				item_panel.change_item_amount_label(ItemManager.held_items[item])
				return	
		var item_panel = ItemPanel.instantiate()
	
		item_container.add_child(item_panel)
		item_panel.change_texture(item["icon"])
		item_panel.change_item_amount_label(ItemManager.held_items[item])
		item_panel.change_name(item['name'])
		
	
func _on_player_gun_equiped(gun_texture):
	gun_container.texture = gun_texture
	
