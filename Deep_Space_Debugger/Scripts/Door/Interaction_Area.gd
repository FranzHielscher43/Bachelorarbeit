extends Area2D

@export var security_door_path : NodePath
@onready var security_door = get_node_or_null(security_door_path)

@onready var dialogbox = $"../../Dialogbox"
var player_nearby := false

@onready var cube = $Polygon2D
var pulse_time := 0.0
var original_cube_scale = Vector2.ONE

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	cube.polygon = PackedVector2Array([
		Vector2(-7, -7),
		Vector2(7, -7),
		Vector2(7, 7),
		Vector2(-7, 7)
	])

	original_cube_scale = cube.scale

func _process(delta):
	if player_nearby and Input.is_action_just_pressed("ui_accept"):
		security_door.interact()
		
	cube.visible = true
	pulse_time += delta
	var pulse = sin(pulse_time * 3.0)
	var scale_factor = 1.0 + pulse * 0.075
	cube.scale = original_cube_scale * scale_factor
	
	if security_door.access_granted:
		cube.color = Color(0.1, 0.9, 0.1, 0.35 + pulse * 0.15)
	else:
		cube.color = Color(0.9, 0.1, 0.1, 0.35 + pulse * 0.15)

func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		dialogbox.show_dialog("Press [ENTER] to open door.", true, "SECURITY DOOR")
		

func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
		dialogbox.hide_dialog()
