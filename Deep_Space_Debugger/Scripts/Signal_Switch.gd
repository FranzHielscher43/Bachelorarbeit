extends Area2D

@export var signal_id := ""
@export var target_path : NodePath
@onready var target = get_node_or_null(target_path)

@export var hint_text := "Press ENTER to send signal"
@export var hint_title := "INFORMATION"
@onready var dialogbox = $"../Dialogbox"
@onready var main_sprite = $MainSprite2D
@onready var activated_sprite = $ActivatedSprite2D

@export var connection_line_path : NodePath
@onready var connection_line = get_node_or_null(connection_line_path)

@export var send_sound_path : NodePath
@onready var send_sound = get_node_or_null(send_sound_path)

var player_nearby := false
var used := false

func _ready():
	activated_sprite.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _process(delta):
	if used:
		main_sprite.visible = false
		activated_sprite.visible = true
		return
	
	if player_nearby:
		var pulse = 0.7 + sin(Time.get_ticks_msec() * 0.006) * 0.3
		main_sprite.modulate = Color.WHITE.lerp(Color(1.4, 1.4, 1.4, 1.0), pulse)
		
		if Input.is_action_just_pressed("ui_accept"):
			send_signal_to_target()
		else:
			main_sprite.modulate = Color.WHITE
			
func send_signal_to_target():
	if used:
		return
	
	if target == null:
		return
	
	if !target.has_method("receive_signal"):
		await dialogbox.show_timed_dialog("Target has no receive_signal method.", 5.0)
		return
	
	if send_sound != null:
		send_sound.play()
	
	await dialogbox.show_timed_dialog(
		"Sender: " + signal_id + "\n\n" +
		"send_signal_to_target()\n" +
		"→ CommunicationServer.receive_signal()\n\n" +
		"Message is being transmitted...",
		5.0
	)
	
	var success = await target.receive_signal(signal_id)
	
	if success:
		used = true
		
		if connection_line != null:
			connection_line.modulate = Color("#15ba12")
	else:
		if connection_line != null:
			connection_line.modulate = Color("#ff4d4d")
			await get_tree().create_timer(2.5).timeout
			connection_line.modulate = Color("#233461")
			
func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		if !used:
			dialogbox.show_dialog(hint_text, true, hint_title)
	
func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
		dialogbox.hide_dialog()
