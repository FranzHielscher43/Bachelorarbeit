extends Node

@export var canvas_modulate_path : NodePath
@export var door_path : NodePath

@export var ambient_sound_before_power_path : NodePath
@onready var ambient_sound_before_power = get_node_or_null(ambient_sound_before_power_path)
@export var ambient_sound_after_power_path : NodePath
@onready var ambient_sound_after_power = get_node_or_null(ambient_sound_after_power_path)

@onready var canvas_modulate = get_node(canvas_modulate_path)
@onready var door = get_node(door_path)
@onready var power_on_sound = $PowerOnSound
@onready var power_off_sound = $PowerOffSound

var power_enabled := false

func _ready():
	canvas_modulate.color = Color(1, 1, 1, 1)
	power_off()

func power_on():
	if power_enabled:
		return
		
	power_enabled = true
	power_on_sound.play()
	
	if ambient_sound_after_power != null:
		ambient_sound_after_power.volume_db = -40
		ambient_sound_after_power.play()
	
	var tween = create_tween()
	
	if ambient_sound_before_power != null:
		tween.parallel().tween_property(ambient_sound_before_power, "volume_db", -40, 3.0)
		
	if ambient_sound_after_power != null:
		tween.parallel().tween_property(ambient_sound_after_power, "volume_db", -8, 3.0)
	
	tween.parallel().tween_property(canvas_modulate, "color", Color(1, 1, 1, 1), 3-0)
	await tween.finished
	
	if ambient_sound_before_power != null:
		ambient_sound_before_power.stop()
	
	door.open_door()

func power_off():
	power_enabled = false
	
	if power_off_sound != null:
		power_off_sound.play()
	
	if power_on_sound != null:
		power_on_sound.stop()
		
	var tween = create_tween()
	tween.tween_property(canvas_modulate, "color", Color(0.4, 0.4, 0.4, 1.0), 2.0)
	
	if ambient_sound_before_power != null:
		tween.parallel().tween_property(ambient_sound_before_power, "volume_db", -8, 2.0)
		
	await tween.finished
