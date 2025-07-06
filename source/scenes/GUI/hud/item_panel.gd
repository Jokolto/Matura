extends Panel


@onready var texture_rect = $TextureRect
@onready var amount_label = $ItemAmountLabel

var item_name: String = ""  # exists for idying purposes

func change_texture(to_texture: Texture):
	if is_instance_valid(to_texture):
		texture_rect.texture = to_texture
	else:
		print("item has no texture or invalid one")

func change_item_amount_label(amount: int):
	amount_label.text = "x" + str(amount)


func change_name(to_name: String):
	item_name = to_name
