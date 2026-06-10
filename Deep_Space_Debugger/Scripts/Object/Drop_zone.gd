extends Area2D

@export var required_class := "Energiekern"
@export var required_attributes := {
	"power": 80,
	"charged": true
} 
@export var door_path : NodePath

@onready var snap_point = $SnapPoint
@onready var door = get_node(door_path)

@onready var dialog_box = $"../Dialogbox" 
@export_multiline var dialog_text = "Korrektes Objekt gefunden!"

@export var completes_mission := ""
@export var completes_subtask := ""

var placed_object = null

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area):
	if placed_object != null:
		return
	
	area.global_position = snap_point.global_position
	
	if !area.has_method("get_inventory_data"):
		return
		
	var item_data = area.get_inventory_data()
	
	var item_class = item_data["class"]
	var item_attributes = item_data["attributes"]
	
	if !is_valid_item(item_class, item_attributes):
		dialog_box.show_dialog("Falsches Objekt!")
		await get_tree().create_timer(2.0).timeout
		dialog_box.hide_dialog()
		return

	placed_object = area
		
	if area.has_method("set_placed"):
		area.set_placed()
			
	dialog_box.show_dialog(dialog_text)	
	if completes_mission != "" and completes_subtask != "":
		MissionManager.complete_subtask(completes_mission, completes_subtask)
	
	await get_tree().create_timer(2.0).timeout
	dialog_box.hide_dialog()

	if door != null:
		door.open_door()

func is_valid_item(item_class, item_attributes) -> bool:

	if item_class != required_class:
		return false
	
	for key in required_attributes.keys():
		if !item_attributes.has(key):
			return false
		var required_value = required_attributes[key]
		var item_value = item_attributes[key]
		if item_value != required_value:
			return false
	return true
