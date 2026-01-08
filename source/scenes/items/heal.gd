extends Pickup

var pickup_heal = 5

func on_pickup(player):
	player.heal(pickup_heal)
	queue_free()
