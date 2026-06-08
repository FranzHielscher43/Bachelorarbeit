extends CanvasLayer

@onready var slots = [
	$Items/VBoxContainer/Slot_01,
	$Items/VBoxContainer/Slot_02,
	$Items/VBoxContainer/Slot_03,
	$Items/VBoxContainer/Slot_04,
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
	items_panel.modulate.a = 0.75
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
	var drop_distance := 24
	
	var directions = [
		player.last_direction,
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT
	]
	
	var final_position = player.global_position
	
	for dir in directions:
		var test_position = player.global_position + dir.normalized() * drop_distance
	
		if !is_position_blocked(test_position):
			final_position = test_position
			break
	
	item.visible = true
	item.set_process(true)
	item.global_position = final_position
	item.get_node("CollisionShape2D").disabled = false
	
func is_position_blocked(test_position: Vector2) -> bool:
	var space_state = get_tree().current_scene.get_world_2d().direct_space_state

	var query = PhysicsPointQueryParameters2D.new()
	query.position = test_position
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var result = space_state.intersect_point(query)
	return result.size() > 0
	
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
	if inventory_open and selected_index >= 0 and selected_index < slots.size():
		slots[selected_index].grab_focus()
	else:
		get_viewport().gui_release_focus()
			
func show_selected_item_info():
	if items.size() == 0:
		dialog_box.hide_dialog()
		return
	
	if selected_index >= items.size():
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
			items_panel.modulate.a = 0.75
			dialog_box.hide_dialog()
			inventory_sound_pitched.play()
			selected_index = -1
			
		update_selection()
	
	if inventory_open:
		if event.is_action_pressed("ui_down"):
			if slots.size() > 0:
				selected_index = min(selected_index + 1, slots.size() - 1)
				inventory_hover_sound.play()
				update_selection()
				show_selected_item_info()
				get_viewport().set_input_as_handled()
		if event.is_action_pressed("ui_up"):
			if slots.size() > 0:
				selected_index = max(selected_index - 1, 0)
				inventory_hover_sound.play()
				update_selection()
				show_selected_item_info()
				get_viewport().set_input_as_handled()
		if event.is_action_pressed("ui_accept"):
			use_item()
			inventory_open = false
			player.stun = false
			items_panel.modulate.a = 0.75
			inventory_use_sound.play()
			update_selection()
