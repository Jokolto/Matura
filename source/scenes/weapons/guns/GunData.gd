class_name GunData extends Resource

@export var fire_rate: float   # shots per second
@export var automatic: bool
@export var spread_deg: float    # 0 = pinpoint
@export var bullet_damage: float
@export var bullets_amount: int
@export var bullet_piercing: int
@export var shooting_range: float
@export var bullet_speed: float
@export var sprite: Texture2D

# sound
@export var stream: AudioStream
@export var pitch_randomness: float = 0.1
@export var volume_db: float = 0.0
