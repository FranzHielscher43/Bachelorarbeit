extends Area2D

@export var required_class := ""
@export var required_attributes := {} 
@export var success_target_path : NodePath
@export var success_method := ""
@onready var success_target = get_node_or_null(success_target_path)

@onready var snap_point = $SnapPoint

@onready var dialog_box = $"../Dialogbox" 
@export_multiline var dialog_text = "Correct object inserted!"

@export var completes_mission := ""
@export var completes_subtask := ""

@onready var cube = $Polygon2D
@onready var line = $Line2D
@export var inactive_line_color := Color("233461ff")
@export var active_line_color := Color("#15ba12")
@export var wrong_line_color := Color("#FF4D4D")

var pulse_time := 0.0
var original_cube_scale = Vector2.ONE

var placed_object = null

func _ready():
	line.default_color = inactive_line_color
	line.width = 2
	area_entered.connect(_on_area_entered)
	
	cube.polygon = PackedVector2Array([
		Vector2(-10, -10),
		Vector2(10, -10),
		Vector2(10, 10),
		Vector2(-10, 10)
	])

	cube.color = Color(0, 1, 1, 0.5)
	original_cube_scale = cube.scale

func _process(delta):
	if placed_object != null:
		cube.visible = false
		return
		
	cube.visible = true
	pulse_time += delta
	var pulse = sin(pulse_time * 3.0)
	var scale_factor = 1.0 + pulse * 0.075
	cube.scale = original_cube_scale * scale_factor
	cube.color = Color(0, 1, 1, 0.35 + pulse * 0.15)

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
		show_wrong_connection()
		dialog_box.show_dialog("Incorrect object")
		await get_tree().create_timer(2.0).timeout
		dialog_box.hide_dialog()
		return

	placed_object = area
	activate_connection()
	
	if area.has_method("set_placed"):
		area.set_placed()
			
	dialog_box.show_dialog(dialog_text)	
	if completes_mission != "" and completes_subtask != "":
		MissionManager.complete_subtask(completes_mission, completes_subtask)
	
	await get_tree().create_timer(2.0).timeout
	dialog_box.hide_dialog()

	if success_target != null and success_method != "":
		if success_target.has_method(success_method):
			success_target.call(success_method)
		else:
			push_warning("Method not found: " + success_method)

func is_valid_item(item_class, item_attributes) -> bool:

	if item_class != required_class:
		return false
	
	for key in required_attributes.keys():
		if !item_attributes.has(key):
			return false
		var required_value = required_attributes[key]
		var item_value = item_attributes[key]
		if str(item_value) != str(required_value):
			return false
	return true
	
func show_wrong_connection():
	var tween = create_tween()
	tween.tween_property(line, "default_color", wrong_line_color, 0.15)
	tween.tween_property(line, "default_color", inactive_line_color, 0.5)

func activate_connection():
	var tween = create_tween()
	tween.tween_property(line, "default_color", active_line_color, 0.5)
	tween.parallel().tween_property(line, "width", 3.0, 0.5)
