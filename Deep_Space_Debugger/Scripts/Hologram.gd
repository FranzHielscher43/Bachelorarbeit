extends StaticBody2D

@export var hologram_title := "OBJECT"
@export_multiline var hologram_description := ""
@export var info_title := "OBJECT"
@export_multiline var info_description := ""

@onready var projector = $ProjectorSprite
@onready var panel = $HologramPanel
@onready var label = $HologramPanel/Panel/Label
@onready var sound = $HologramSound
@export var dialogbox_path : NodePath
@onready var dialogbox = get_node_or_null(dialogbox_path)
@onready var light_cone = $LightCone
@export var hologram_color := Color("#66FFFF")

@onready var interaction_area = $Area2D

var time := 0.0

var player_nearby := false
var is_open := false

var panel_start_scale := Vector2.ONE
var light_cone_start_scale := Vector2.ONE

func _ready():
	panel.visible = false
	light_cone.visible = false
	light_cone.modulate.a = 0.0
	
	panel_start_scale = panel.scale
	light_cone_start_scale = light_cone.scale
	
	panel.modulate = hologram_color
	light_cone.modulate = hologram_color
	
	light_cone.color = Color(hologram_color.r, hologram_color.g, hologram_color.b, 1.0)
	light_cone.modulate = Color(hologram_color.r, hologram_color.g, hologram_color.b, 1.0)

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _process(delta):
	time += delta

	if panel.visible:
		panel.rotation_degrees = sin(time * 1.5) * 0.5
		light_cone.rotation_degrees = sin(time * 1.5) * 0.5
		
		var pulse = 0.58 + sin(time * 2.0) * 0.1
		panel.modulate = Color(
			hologram_color.r,
			hologram_color.g,
			hologram_color.b,
			pulse
		)
		light_cone.modulate = Color(
			hologram_color.r,
			hologram_color.g,
			hologram_color.b,
			0.45
		)
		
	if player_nearby and is_open and Input.is_action_just_pressed("ui_accept"):
		dialogbox.show_dialog(info_description, true, info_title)

func open_hologram():
	is_open = true
	panel.visible = true
	light_cone.visible = true

	if sound != null:
		sound.play()

	label.text = hologram_title + "\n" + hologram_description
				
	panel.scale = Vector2(panel_start_scale.x, 0)
	light_cone.scale = Vector2(light_cone_start_scale.x, 0)

	var start_pulse = 0.58
	panel.modulate = Color(hologram_color.r, hologram_color.g, hologram_color.b, start_pulse)
	light_cone.modulate = Color(hologram_color.r, hologram_color.g, hologram_color.b, 0.45)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", panel_start_scale, 0.2)
	tween.tween_property(light_cone, "scale", light_cone_start_scale, 0.2)

func close_hologram():
	is_open = false
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(panel_start_scale.x, 0), 0.2)
	tween.tween_property(light_cone, "scale", Vector2(light_cone_start_scale.x, 0), 0.2)
	tween.tween_property(light_cone, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	panel.visible = false
	light_cone.visible = false
	dialogbox.hide_dialog()
		
func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		if !is_open:
			open_hologram()

func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
		if is_open:
			close_hologram()
