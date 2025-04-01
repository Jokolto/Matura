extends CharacterBody2D

@onready var anim_sprite = $AnimatedSprite2D 
var speed = 200  # Movement speed


func _process(delta):
	# Get player input (WASD or arrow keys)
	velocity = Vector2()  # Reset velocity
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	
	
	# Normalize the velocity to avoid diagonal speed boost
	velocity = velocity.normalized() * speed
	
	# Move the player using KinematicBody2D's move_and_slide method
	move_and_slide()
