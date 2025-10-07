extends Node2D

var music_player: AudioStreamPlayer
var current_music: AudioStream = null
var music_volume: float

var menu_music_resource = preload("res://resources/music/mainmenu.tres")
var level_music_resource = preload("res://resources/music/level.tres")
var death_music_resource = preload("res://resources/music/deadmenu.tres")
 
var menu_music: AudioStream
var level_music: AudioStream
var death_music: AudioStream


const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"


func _ready():
	music_volume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.state_changed.connect(_on_game_state_changed)
	
	menu_music = menu_music_resource.stream.duplicate()
	level_music = level_music_resource.stream.duplicate()
	death_music = death_music_resource.stream.duplicate()
	
	music_player = AudioStreamPlayer.new()
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	music_player.bus = MUSIC_BUS
	add_child(music_player)


# music
func play_music(stream: AudioStream, loop: bool = true):
	if current_music == stream:
		return
	current_music = stream
	music_player.stream = stream
	music_player.stream.loop = loop
	music_player.volume_db = music_volume
	music_player.play()

func stop_music():
	music_player.stop()
	current_music = null

func _fade_to_music(new_music: AudioStream, duration: float, loop: bool = true):
	var old_player = music_player
	var new_player = AudioStreamPlayer.new()
	new_player.stream = new_music
	new_player.stream.loop = loop
	new_player.bus = "Music"
	new_player.volume_db = -80 # start silent
	add_child(new_player)
	new_player.play()

	var tween := create_tween()
	tween.tween_property(new_player, "volume_db", music_volume, duration)
	tween.tween_property(old_player, "volume_db", -80, duration)
	tween.tween_callback(Callable(old_player, "queue_free"))
	music_player = new_player



# sfx
func play_sfx(stream: AudioStream, pos = null, volume := 0.0, pitch_randomness := 0.0, parent: Node = self) -> void:
	# Choose class depending on whether positional audio is needed
	var player_class = AudioStreamPlayer if pos == null else AudioStreamPlayer2D
	var player: Node = player_class.new()
	parent.add_child(player)

	# assign stream and props
	player.stream = stream
	player.volume_db = volume
	if pitch_randomness > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)
	else:
		player.pitch_scale = 1.0

	if pos != null and player is AudioStreamPlayer2D:
		player.global_position = pos

	player.play()

	# Try to get length; fallback to 1.0s if not available
	var length := 1.0
	if stream != null and stream.has_method("get_length"):
		length = float(stream.get_length())

	# wait and free the player (async helper)
	_free_player_later(player, length + 0.05)


# async helper
func _free_player_later(player: Node, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(player):
		player.queue_free()

func _on_game_state_changed(state: String):
	match state:
		"MENU":
			if music_player.stream != menu_music:
				_fade_to_music(menu_music, 0.25)
		"PLAYING":
			if music_player.stream != level_music:
				_fade_to_music(level_music, 0.25)
		"GAME_OVER":
			if music_player.stream != death_music:
				_fade_to_music(death_music, 0.25)

# so nothing leaks
func _exit_tree():
	if is_instance_valid(music_player):
		music_player.queue_free()
	music_player = null
	
	# all audio stream must queued free before closing the game
	for child in get_children():
		if child is AudioStreamPlayer2D:
			child.stop()
			child.queue_free()
