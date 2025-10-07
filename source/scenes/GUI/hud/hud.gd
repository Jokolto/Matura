extends CanvasLayer


@onready var health_bar: ProgressBar = $MarginContainer/StatusVBoxContainer/MarginContainer/HealthBar
@onready var health_label = $MarginContainer/StatusVBoxContainer/MarginContainer/Label
@onready var enemies_bar: ProgressBar = $MarginContainer/EnemiesVBoxContainer/MarginContainer/EnemiesCountBar
@onready var enemies_label = $MarginContainer/EnemiesVBoxContainer/MarginContainer/Label
@onready var wave_label = $MarginContainer/EnemiesVBoxContainer/Label
@onready var enemies_bar_container = $MarginContainer/EnemiesVBoxContainer/MarginContainer

@onready var gun_texture = $GunMarginContainer/TextureRect
@onready var ammo_label = $GunMarginContainer/Label
@onready var gun_hud = $GunMarginContainer

@onready var item_container = $ItemsContainer/ItemsHBoxContainer
@onready var dmg_overlay = $DamageOverlay

@onready var wave_end_label = $Label

var player = null # set by level node
var ItemManager = null # set by level node

var item_panels: Array = []
var ItemPanel: PackedScene = preload("res://scenes/GUI/hud/item_panel.tscn")

var dmg_overlay_tween: Tween

func _ready() -> void:
	EntitiesManager.wave_start.connect(_on_wave_start)
	EntitiesManager.wave_end.connect(_on_wave_end)
	
	GameManager._set_hud(self)
	gun_hud.visible = false
	wave_end_label.visible = false
	wave_label.text = "Rest time"
	enemies_bar_container.visible = false
	
	
func set_item_manager(manager):
	ItemManager = manager

	
func set_health(value: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = value
	var hp_str = ("%.1f" % value).rstrip("0").rstrip(".")
	var max_hp_str = ("%.1f" % max_value).rstrip("0").rstrip(".")
	health_label.text = hp_str + " / " + max_hp_str

func set_enemy_hud(value: int, max_value: int) -> void:
	enemies_bar.max_value = max_value
	enemies_bar.value = value
	enemies_label.text = "Enemies left: " + "%d / %d" % [value, max_value]
	
func set_player(player_scene):
	player = player_scene


func save_item_panels():
	item_panels = item_container.get_children()
	GameManager.stored_item_panels = item_panels
	
	
func show_damage_overlay():
	dmg_overlay.visible = true
	
	if dmg_overlay_tween:
		dmg_overlay_tween.kill()
		
	dmg_overlay.material.set("shader_parameter/strength", 0.5)
	dmg_overlay_tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
	dmg_overlay_tween.tween_property(dmg_overlay.material, "shader_parameter/strength", 0.0, 0.5) # fade out in 0.5s
	
func _on_player_damaged(_damage):
	show_damage_overlay()
	set_health(player.hp, player.max_hp)

func _on_enemy_death(_enemy):
	set_enemy_hud(EntitiesManager.enemies_alive, EntitiesManager.enemies_per_wave)
	
func _on_wave_start():
	enemies_bar_container.visible = true
	wave_label.text = "Wave: " + str(EntitiesManager.current_wave)

func _on_wave_end(_fitness_dict):
	enemies_bar_container.visible = false
	wave_label.text = "Rest time"
	wave_end_label.visible = true
	wave_end_label.text = "Wave %s End" % [EntitiesManager.current_wave]

	

func _on_enemy_spawned():
	set_enemy_hud(EntitiesManager.enemies_alive, EntitiesManager.enemies_per_wave)
	
func _on_upgrade_selected(item):
	wave_end_label.visible = false
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

	

func _on_player_weapon_equiped(gun_stats):
	gun_hud.visible = true
	gun_texture.texture = gun_stats.sprite
	if "ammo" in gun_stats:
		ammo_label.text = "%d / %d" % [gun_stats.ammo, gun_stats.ammo]
	else:
		ammo_label.text = ''
	
func _on_player_shoot(gun):
	ammo_label.text = "%d / %d" % [gun.ammo, gun.stats.ammo]
	if GlobalConfig.infinite_ammo_ranged:
		ammo_label.text = "∞ / ∞"

func _on_player_healed(_value):
	set_health(player.hp, player.max_hp)


func _on_player_death():
	save_item_panels()

func _on_win():
	save_item_panels()
