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

# Number of players to preload in the pool
const POOL_SIZE := 50.0

# Separate pools for 2D and regular SFX
var pool: Array[AudioStreamPlayer] = []
var pool_2d: Array[AudioStreamPlayer2D] = []


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
	# Preload regular AudioStreamPlayers
	for i in floor(POOL_SIZE/5):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		pool.append(player)

	# Preload 2D AudioStreamPlayers
	for i in ceil(POOL_SIZE*4/5):
		var player2d = AudioStreamPlayer2D.new()
		player2d.bus = "SFX"
		add_child(player2d)
		pool_2d.append(player2d)


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
func play_sfx(stream: AudioStream, pos = null, volume: float = 0.0, pitch_randomness: float = 0.0,  parent: Node = self):
	var player
	# Decide which pool to use
	if pos != null:
		if len(pool_2d) == 0:
			push_warning("No available AudioStreamPlayer2D in pool! Increase POOL_SIZE.")
			return
		player = pool_2d.pop_front()
		player.global_position = pos
	else:
		if len(pool) == 0:
			push_warning("No available AudioStreamPlayer in pool! Increase POOL_SIZE.")
			return
		player = pool.pop_front()

	# Stop previous playback and assign stream
	player.stop()
	player.stream = stream
	player.volume_db = volume
	
	# Pitch randomness
	if pitch_randomness > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)
	else:
		player.pitch_scale = 1.0

	# Reparent if necessary
	if player.get_parent() != parent:
		player.get_parent().remove_child(player)
		parent.add_child(player)

	# Disconnect previous connections
	#player.finished.disconnect()
	
	if not player.finished.is_connected(_return_player_to_pool.bind(player)):
		player.finished.connect(_return_player_to_pool.bind(player))
	player.play()

func _return_player_to_pool(player):
	if player is AudioStreamPlayer2D:
		pool_2d.append(player)
	else:
		pool.append(player)

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
