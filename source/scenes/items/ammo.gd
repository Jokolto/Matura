extends Pickup


func on_pickup(player):
	player.reload()
	queue_free()
