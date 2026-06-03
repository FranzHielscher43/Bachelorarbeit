extends Area2D

@export var required_item_id := "object_1"
@export var door_path : NodePath

@onready var snap_point = $SnapPoint
@onready var door = get_node(door_path)

@onready var dialog_box = $"../Dialogbox" 
@export_multiline var dialog_text = ""

var placed_object = null

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area):
	if placed_object != null:
		return
	
	if !area.has_method("get_item_id"):
		return

	area.global_position = snap_point.global_position
	if area.get_item_id() == required_item_id:
		placed_object = area
		
		if area.has_method("set_placed"):
			area.set_placed()
			
		dialog_box.show_dialog(dialog_text)
		
		await get_tree().create_timer(2.0).timeout
		dialog_box.hide_dialog()

		if door != null:
			door.open_door()
	else:
		dialog_box.show_dialog("Falsches Objekt!")
		await get_tree().create_timer(2.0).timeout
		dialog_box.hide_dialog()
