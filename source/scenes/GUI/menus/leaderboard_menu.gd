extends Control

@onready var menu_button: TextureButton = $MenuButton
@onready var http = $HTTPRequest
@onready var wave_reached_list = $WaveReachedLeaderboard/ScrollContainer/LeaderboardList
@onready var best_time_list = $TimeLeaderboard/ScrollContainer/LeaderboardList

func _ready():
	menu_button.pressed.connect(_on_menu_pressed)
	http.request_completed.connect(_on_request_completed)
	fetch_leaderboard()
	
func _on_menu_pressed():
	get_tree().paused = false
	GameManager.state = "MENU"
	GameManager.change_scene()


func fetch_leaderboard() -> void:
	http.request(GlobalConfig.FIREBASE_URL)

func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		return
	
	var text = body.get_string_from_utf8()
	var json_data = {}
	if text != "":
		var json = JSON.new()
		var error = json.parse(text)
		json_data = json.data
	
	var entries = []
	for key in json_data.keys():
		var e = json_data[key]
		entries.append({
			"name": e.get("name", ""),
			"wave": int(e.get("wave", 0)),
			"time": int(e.get("time", 0))
		})
	
	# Sort by wave (descending)
	var by_wave = entries.duplicate()
	by_wave.sort_custom(func(a, b): return a["wave"] > b["wave"])
	
	# Sort by time (ascending)
	var by_time = entries.duplicate()
	by_time.sort_custom(func(a, b): return a["time"] < b["time"])
	
	# Update UI
	_update_leaderboard_ui(wave_reached_list, by_wave, "Wave", false)
	_update_leaderboard_ui(best_time_list, by_time, "Time", true)


func _update_leaderboard_ui(container: VBoxContainer, entries: Array, _metric: String, show_time: bool) -> void:
	# Clear old children
	for child in container.get_children():
		child.queue_free()
	
	var max_entries = min(entries.size(), 10)
	for i in range(max_entries):
		var e = entries[i]
		var label = Label.new()
		
		if show_time:
			label.text = "%d. %s  - Time: %ds" % [
				i + 1, e["name"], e["time"]
			]
		else:
			label.text = "%d. %s  - Wave: %d" % [
				i + 1, e["name"], e["wave"]
			]
		
		container.add_child(label)
