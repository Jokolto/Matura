extends Control

@onready var BackButton = $MarginContainer/VBoxContainer2/BackButton

func _ready():
	BackButton.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	GameManager.state = "MENU"
	GameManager.change_scene()
