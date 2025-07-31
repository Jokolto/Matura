extends Control

@onready var BackButton = $Panel/Buttons/BackButton
@onready var music_slider = $Panel/Buttons/MusicHSlider
@onready var sfx_slider = $Panel/Buttons/SoundHSlider


func _ready():
	BackButton.pressed.connect(_on_back_pressed)
	# Load saved values if any
	music_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	sfx_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))
	
	# Connect value changed signal
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

func _on_back_pressed():
	GameManager.state = "MENU"
	GameManager.change_scene()


func _on_music_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
	AudioManager.music_volume = value

func _on_sfx_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)
