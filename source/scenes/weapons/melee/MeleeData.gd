class_name MeleeData extends Resource

@export var scene_path: String = "res://scenes/weapons/melee/melee_weapon.tscn"

@export var fire_rate: float   # attacks per second
@export var attack_damage: float
@export var reach: float = 20.0  # how far in front of holder
@export var swing_angle: float = 180.0  # total angle of the swing
@export var swing_speed: float = 720.0  # degrees per second
@export var automatic: bool = false
@export var sprite: Texture2D

@export var attack_sound: AudioStream
@export var volume_db: float
@export var pitch_randomness: float
