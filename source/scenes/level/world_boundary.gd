extends Area2D

signal won

func _on_body_entered(body):
	if body is Player:
		won.emit()
		
