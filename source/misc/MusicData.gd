class_name MusicData
extends Resource

@export var stream: AudioStream = null
@export var fade_in_time: float = 1.5
@export var fade_out_time: float = 1.5
@export var volume_db: float = 0.0
@export var loop: bool = true
@export var tag: String = "" # for easy matching (e.g. "menu", "combat")
