extends Button

@onready var inventory = $"../../Inventory"

func _ready():
	visible = DisplayServer.is_touchscreen_available()

func _pressed():
	if inventory.inventory_open:
		inventory.drop_selected_from_mobile()
		return
	
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
