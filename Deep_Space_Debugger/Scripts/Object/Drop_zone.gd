extends Area2D

@export var required_item_id := "object_1"
@export var door_path : NodePath

@onready var snap_point = $SnapPoint
@onready var door = get_node(door_path)

@onready var dialog_box = $"../Dialogbox"
@export_multiline var dialog_text = "Korrektes Objekt gefunden!"

var placed_object = null

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area):
	if placed_object != null:
		return

	if area.get_item_id() == required_item_id and !area.is_carried:
		placed_object = area
		area.global_position = snap_point.global_position
		area.set_process(false)
		dialog_box.show_dialog(dialog_text)
		await get_tree().create_timer(2.0).timeout
		dialog_box.hide_dialog()

		if door != null:
			door.open_door()
	else:
		print("Falsches Objekt!")
