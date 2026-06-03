extends Area2D

@export_multiline var dialog_text = "Das ist ein interagierbares Objekt."
@export var prompt_text = ""

@onready var prompt_label = $Label
@onready var dialog_box = $"../Dialogbox"

var player_nearby := false
var interacted := false

@onready var sprite = $Sprite2D

var original_scale : Vector2

func _ready():
	original_scale = sprite.scale
	prompt_label.text = prompt_text
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		prompt_label.visible = true
		
func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
		interacted = false
		prompt_label.visible = false
		sprite.scale = original_scale
		dialog_box.hide_dialog()
		
func _process(delta):
	if player_nearby and !interacted:
		var pulse = 0.7 + sin(Time.get_ticks_msec() * 0.005) * 0.3
		sprite.modulate = Color.WHITE.lerp(Color(1.5, 1.5, 1.5, 1.0), pulse)
		if Input.is_action_just_pressed("ui_accept"):
			interacted = true
			sprite.scale = original_scale
			dialog_box.show_dialog(dialog_text)
	else:
		sprite.scale = original_scale
		sprite.modulate = Color.WHITE
