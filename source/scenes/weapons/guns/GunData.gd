class_name GunData extends Resource

@export var scene_path: String = "res://scenes/weapons/guns/gun1.tscn"
@export var rarity: int = 1

@export var fire_rate: float   # shots per second
@export var automatic: bool
@export var spread_deg: float    # 0 = pinpoint
@export var bullet_damage: float
@export var bullets_amount: int
@export var bullet_piercing: int
@export var shooting_range: float
@export var bullet_speed: float

@export var sprite: Texture2D
@export var name: String
@export var description: String

# sound
@export var on_shoot_sound: AudioStream
@export var shoot_sound_pitch_randomness: float = 0.1
@export var shoot_sound_volume_db: float = 0.0
