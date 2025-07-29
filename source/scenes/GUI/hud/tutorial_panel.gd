extends CanvasLayer

@onready var label: Label = $Panel/Label
@onready var panel: Panel = $Panel
@onready var button: Button = $Panel/Resume

var active: bool = false
var shown_tutorials := {}


var tutorial_texts := {
	"move": "Use WASD to move.",
	"attack": "Use your mouse to aim and use left mouse button to attack.",
	"dash": "Press right mouse button to dash.",
	"pickup": "Press E to pick up weapons.",
	"goal": "Break the gate to escape the goblin camp."
}


func show_tutorial_piece(key: String) -> void:
	if key in tutorial_texts and not shown_tutorials.has(key) and GameManager.tutorial_enabled:
		show_tutorial(tutorial_texts[key])
		shown_tutorials[key] = true

func show_tutorial(text: String) -> void:
	Input.set_custom_mouse_cursor(null)
	label.text = text
	visible = true
	active = true
	GameManager.toggle_pause()

func _on_resume_pressed() -> void:
	visible = false
	active = false
	GameManager.toggle_pause()


func _on_player_weapon_nearby():
	show_tutorial_piece('pickup')
