extends Area2D

@export var limit_left := 0
@export var limit_right := 0
@export var limit_top := 0
@export var limit_bottom := 0

func _ready():
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if body.name == "Player":
		var camera = body.get_node("Camera2D")
		
		camera.limit_left = limit_left
		camera.limit_right = limit_right
		camera.limit_top = limit_top
		camera.limit_bottom = limit_bottom
