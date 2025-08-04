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


# === MUSIC ===
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



# === SFX ===
func play_sfx(stream: AudioStream, volume: float = 0.0, pitch_randomness: float = 0.0, parent=self):
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = SFX_BUS
	sfx_player.stream = stream
	sfx_player.volume_db = volume

	if pitch_randomness > 0.0:
		sfx_player.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)

	parent.add_child(sfx_player)
	sfx_player.play()
	sfx_player.connect("finished", Callable(sfx_player, "queue_free"))
	
	
func play_sfx_positional(stream: AudioStream, play_at_position: Vector2, volume: float = 0.0, pitch_randomness: float = 0.0, parent=self):
	var sfx_player = AudioStreamPlayer2D.new()
	sfx_player.bus = SFX_BUS
	sfx_player.stream = stream
	sfx_player.volume_db = volume
	sfx_player.global_position = play_at_position

	if pitch_randomness > 0.0:
		sfx_player.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)

	parent.add_child(sfx_player)
	sfx_player.play()
	
	sfx_player.connect("finished", Callable(sfx_player, "queue_free"))


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
