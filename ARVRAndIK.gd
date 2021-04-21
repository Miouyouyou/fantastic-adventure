extends ARVROrigin

# FIXME Let the user choose !
onready var holding_hand_items = $ManetteDroite/Items

func item_equipped() -> bool:
	return holding_hand_items.get_child_count() > 0

func equip(item:Spatial):
	NodeHelpers.remove_children(holding_hand_items)
	holding_hand_items.add_child(item)

func use():
	for item in holding_hand_items.get_children():
		item.use()
