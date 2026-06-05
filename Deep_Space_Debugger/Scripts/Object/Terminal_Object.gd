extends Area2D

@onready var terminal = $"../Terminal"

var player_nearby := false
var interacted := false

@onready var sprite = $Sprite2D
var original_scale : Vector2

func _ready():
	original_scale = sprite.scale
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		
func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
		interacted = false
		sprite.modulate = Color.WHITE
		
func _process(delta):
	if player_nearby and !interacted:
		var pulse = 0.7 + sin(Time.get_ticks_msec() * 0.005) * 0.3
		sprite.modulate = Color.WHITE.lerp(Color(1.5, 1.5, 1.5, 1.0), pulse)
		if Input.is_action_just_pressed("ui_accept"):
			interacted = true
			sprite.modulate = Color.WHITE
			terminal.open_terminal()
	else:
		sprite.modulate = Color.WHITE
