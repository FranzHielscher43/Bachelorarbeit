extends Control

@onready var knob = $Knob
@export var radius := 50.0

var dragging := false
var direction := Vector2.ZERO
var knob_start_position := Vector2.ZERO
var active_touch_index := -1

func _ready():
	visible = true # zum Testen
	knob_start_position = knob.position

func _input(event):
	if !visible:
		return

	if event is InputEventScreenTouch:
		var local_pos = get_global_transform().affine_inverse() * event.position

		if event.pressed and Rect2(Vector2.ZERO, size).has_point(local_pos):
			dragging = true
			active_touch_index = event.index
			update_joystick(local_pos)
			get_viewport().set_input_as_handled()

		elif !event.pressed and event.index == active_touch_index:
			dragging = false
			active_touch_index = -1
			direction = Vector2.ZERO
			knob.position = knob_start_position
			release_actions()
			get_viewport().set_input_as_handled()

	if event is InputEventScreenDrag and dragging and event.index == active_touch_index:
		var local_pos = get_global_transform().affine_inverse() * event.position
		update_joystick(local_pos)
		get_viewport().set_input_as_handled()

func update_joystick(local_pos: Vector2):
	var center = size / 2
	var offset = local_pos - center

	if offset.length() > radius:
		offset = offset.normalized() * radius

	knob.position = knob_start_position + offset
	direction = offset / radius
	update_actions()

func update_actions():
	release_actions()

	if direction.x < -0.3:
		Input.action_press("ui_left")
	elif direction.x > 0.3:
		Input.action_press("ui_right")

	if direction.y < -0.3:
		Input.action_press("ui_up")
	elif direction.y > 0.3:
		Input.action_press("ui_down")

func release_actions():
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_up")
	Input.action_release("ui_down")
