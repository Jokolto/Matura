extends Control

@onready var play_again_button: TextureButton = $Panel/Buttons/PlayButton
@onready var credits_button: TextureButton = $Panel/Buttons/CreditsButton
@onready var menu_button: TextureButton = $Panel/Buttons/MenuButton
@onready var items_grid_container = $Panel/ItemsContainer/ItemsGridContainer
@onready var stat_label = $Panel/statsvcontainer/statLabel
@onready var submit_button = $Panel/Buttons/SubmitButton
@onready var submit_button_label = $Panel/Buttons/SubmitButton/Label
@onready var nickname_input = $PlayerNameInput
@onready var http = $HTTPRequest


func _ready():
	var item_panels = GameManager.stored_item_panels
	play_again_button.pressed.connect(_on_play_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	submit_button.pressed.connect(_on_submit_button_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	for item_panel: Panel in item_panels:
		item_panel.get_parent().remove_child(item_panel)
		items_grid_container.add_child(item_panel)
	
	var stats: String = """
	Wave reached: %d
	Enemies slaughtered: %d
	Time: %d
						""" % [EntitiesManager.current_wave, EntitiesManager.total_enemies_killed, round(EntitiesManager.won_time_sec*10)/10]
	
	stat_label.text = stats


# Submit a score
func submit_score(player_name: String, wave: int, time_seconds: int) -> void:
	var safe_name = player_name.strip_edges().replace(" ", "_")
	var data = {
		"name": safe_name,
		"wave": wave,
		"time": time_seconds
	}
	var json_body = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	http.request(GlobalConfig.FIREBASE_URL, headers, HTTPClient.METHOD_POST, json_body)

func _on_play_again_pressed():
	GameManager.state = "PLAYING"
	GameManager.change_scene()

func _on_menu_pressed():
	get_tree().paused = false
	GameManager.state = "MENU"
	GameManager.change_scene()
	
	
func _on_credits_pressed():
	GameManager.state = "CREDITS"
	GameManager.change_scene()

func _on_submit_button_pressed() -> void:
	if GlobalConfig.PlayerNickName == "":
		if not nickname_input.visible:
			nickname_input.visible = true
			return
		
		var proposed_name = nickname_input.text.strip_edges()
		if proposed_name == "" or "*" in proposed_name or "|" in proposed_name:
			nickname_input.text = "invalid nickname"
			return
		GlobalConfig.PlayerNickName = proposed_name
		
	submit_score(GlobalConfig.PlayerNickName, EntitiesManager.current_wave, round(EntitiesManager.won_time_sec))
	nickname_input.visible = false
	submit_button.disabled = true
	submit_button_label.text = "Submited"
