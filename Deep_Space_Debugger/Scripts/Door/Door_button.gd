extends Area2D

@export var door_path: NodePath
@onready var door = get_node(door_path)
@onready var button_sound = $ButtonSound

var player_nearby := false
var activated := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta):
	if player_nearby and !activated and Input.is_action_just_pressed("ui_accept"):
		activated = true
		button_sound.play()
		if door != null:
			open_door_delayed()
			
func open_door_delayed():
	await get_tree().create_timer(1.25).timeout
	door.open_door()

func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true


func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false 
