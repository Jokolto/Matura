extends CanvasLayer

@onready var pickupbutton = $Control/PickupButton
@onready var attack_joystick = $AttackJoystick
var player = null

func _ready() -> void:
	if GameManager.is_mobile:
		visible = true
	else:
		visible = false

# seems quite inefficient, could be optimised if performance will go bad
func _process(delta: float) -> void:
	if GameManager.is_mobile and player.nearby_pickups.size() > 0:
		pickupbutton.visible = true
	else:
		pickupbutton.visible = false
	
func get_aim_vector() -> Vector2:
	return attack_joystick.output


func set_player(player_instance):
	player = player_instance
