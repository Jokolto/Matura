extends CanvasLayer

@onready var label: Label = $Panel/Label
@onready var panel: Panel = $Panel
@onready var button: Button = $Panel/Resume

var active: bool = false
var shown_tutorials: Dictionary = GameManager.shown_tutorials


var tutorial_texts := {
	"move": 	"""
	Oh no, it seems you were teleported straight into goblin's camp (how unfortunate!). Let's see if there anything laying on floor to help you escape. 
	
	Use WASD to move.
				""",
	
	"pickup":	"""
	Oh what a nice looking stick! It for sure can deal insane damages to that gate, so you can escape!
	
	Press E to pick up weapons.
				""",
				
	"gate": 	"""
	It seems, tree branches are not the best weapons. Maybe goblins have some real weapons. They do not seem to want to give you their weapons though (how unfriendly!).
	
	Use your mouse to aim and use left mouse button to tickle the goblins with the stick.
				"""
}

func _ready() -> void:
	GameManager.tutorials_amount = len(tutorial_texts)

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
	
func _on_gate_regen_first_time():
	show_tutorial_piece('gate')
