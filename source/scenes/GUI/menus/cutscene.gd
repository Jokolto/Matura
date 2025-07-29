extends Control

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var skip_button: TextureButton = $SkipButton
@onready var fade_rect: ColorRect = $ColorRect  # for fade-out
@onready var goblin: AnimatedSprite2D = $goblin  # for fade-out
@onready var portal: AnimatedSprite2D = $portal

func _ready():
	skip_button.pressed.connect(_on_skip_pressed)
	_start_cutscene()

func _start_cutscene():
	anim_player.play("cutscene_intro")

func _on_cutscene_end():
	# Called at end of animation (via AnimationPlayer signal)
	_fade_out()

func _fade_out():
	fade_rect.visible = true
	anim_player.play("fade_out")  # fade_rect modulate.a from 0 to 1

func _on_fade_complete():
	Logger.log("Switched to game", "DEBUG")
	GameManager.state = "PLAYING"
	GameManager.change_scene()

func _on_skip_pressed():
	_fade_out()
