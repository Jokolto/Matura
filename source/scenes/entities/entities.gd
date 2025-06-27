extends Node



func _ready() -> void:
	EntitiesManager.set_entities_node(self)
	EntitiesManager.set_enemies_node($Enemies)
