extends StaticBody2D

@export var open_offset := Vector2(0, -64)
@export var open_speed := 0.4
@onready var door_sound = $DoorSound

var closed_position : Vector2
var open_position : Vector2
var is_open := false

func _ready():
	closed_position = position
	open_position = closed_position + open_offset
	
func open_door():
	if is_open:
		return
	
	is_open = true
	door_sound.play()
	
	var tween = create_tween()
	tween.tween_property(self, "position", open_position, open_speed)
