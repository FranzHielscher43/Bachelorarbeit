extends CanvasLayer

@onready var slots = [
	$Items/VBoxContainer/Slot_01,
	$Items/VBoxContainer/Slot_02,
	$Items/VBoxContainer/Slot_03,
	$Items/VBoxContainer/Slot_04,
	$Items/VBoxContainer/Slot_05
]

@onready var player = $"../Player"
@onready var dialog_box = $"../Dialogbox"
@onready var items_panel = $Items
@onready var inventory_sound = $InventorySound
@onready var inventory_sound_pitched = $InventorySoundPitched
@onready var inventory_hover_sound = $HoverSound
@onready var inventory_use_sound = $UseSound

var items := []
var selected_index := 0
var inventory_open := false

func _ready():
	items_panel.modulate.a = 0.6
	update_slots()
	
func add_item(item_data):
	if items.size() >= 5:
		print("Inventar voll")
		return
	items.append(item_data)
	update_slots()
	
func use_item():
	if items.size() == 0:
		return
		
	if selected_index >= items.size():
		return
		
	var item_data = items[selected_index]
	drop_item(item_data)
	
	items.remove_at(selected_index)
	if selected_index >= items.size():
		selected_index = max(items.size() - 1, 0)
		
	update_slots()

func drop_item(item_data):
	var item = item_data["object"]
	
	item.visible = true
	item.set_process(true)
	
	item.global_position = player.global_position + player.last_direction.normalized() * 32
	item.get_node("CollisionShape2D").disabled = false
	
func update_slots():
	for i in range(slots.size()):
		var icon = slots[i].get_node("Icon")
		if i < items.size():
			icon.texture = items[i]["texture"]
			icon.visible = true
		else:
			icon.texture = null
			icon.visible = false
	
	update_selection()
	
func update_selection():
	for i in range(slots.size()):
		if inventory_open and i == selected_index:
			slots[i].modulate = Color(1.4, 1.4, 1.4, 1.0)
		else:
			slots[i].modulate = Color.WHITE
			
func show_selected_item_info():
	if items.size() == 0:
		dialog_box.hide_dialog()
		return
	
	if selected_index > items.size():
		return
		
	var item = items[selected_index]
	
	var info_text = "Objekt: " + item["name"] + "\n"
	info_text += "Klasse: " + item["class"] + "\n"
	if item["attributes"] != "":
		info_text += item["attributes"]
	
	dialog_box.show_dialog(info_text)
	
func _input(event):
	if event.is_action_pressed("inventory"):
		inventory_open = !inventory_open
		player.stun = inventory_open
		
		if inventory_open:
			selected_index = 0
			show_selected_item_info()
			items_panel.modulate.a = 1.0
			inventory_sound.play()
		else:
			items_panel.modulate.a = 0.6
			dialog_box.hide_dialog()
			inventory_sound_pitched.play()
			selected_index = -1
			
		update_selection()
	
	if inventory_open:
		if event.is_action_pressed("ui_down"):
			if items.size() > 0:
				selected_index = min(selected_index + 1, items.size() - 1)
				inventory_hover_sound.play()
				update_selection()
				show_selected_item_info()
		if event.is_action_pressed("ui_up"):
			if items.size() > 0:
				selected_index = max(selected_index - 1, 0)
				inventory_hover_sound.play()
				update_selection()
				show_selected_item_info()
		if event.is_action_pressed("ui_accept"):
			use_item()
			inventory_open = false
			player.stun = false
			items_panel.modulate.a = 0.6
			inventory_use_sound.play()
			update_selection()
