extends Area2D

@export var door_path: NodePath
@onready var door = get_node(door_path)

var player_nearby := false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta):
	if player_nearby and Input.is_action_just_pressed("ui_accept"):
		if door != null:
			door.open_door()
		else:
			print("Keine Tür gefunden!")


func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true


func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false 
