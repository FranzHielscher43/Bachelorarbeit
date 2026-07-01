extends Area2D
class_name AICore

@onready var dialogbox = $"../Dialogbox"
var dialog_id := 0
var communication_online := false

var repair_done := false
var security_done := false
var transport_done := false

var player_nearby := false
var station_rebooted := false

@export var door_path : NodePath
@onready var door = get_node_or_null(door_path)

@export var credits_path := "res://Scenes/Level/Credits.tscn"

@export var canvas_modulate_path : NodePath
@onready var canvas_modulate = get_node_or_null(canvas_modulate_path)

@onready var repair_effect = $RepairEffect
@onready var repair_sound = $RepairSound

var core_online := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _process(_delta):
	if player_nearby and core_online and !station_rebooted:
		if Input.is_action_just_pressed("ui_accept"):
			station_rebooted = true
			MissionManager.complete_subtask("ai_core", "Reboot space station")
			await reboot_station()

func activate_communication():
	communication_online = true
	dialogbox.show_dialog("Station Server online.\n\n" +"Communication channels restored.\n\n" +"AI Core can now receive method calls.",true, "STATION SERVER")
	await get_tree().create_timer(5.0).timeout
	dialogbox.hide_dialog()

func receive_robot_task(bot):
	if !communication_online:
		await show_timed_dialog("Station server offline.\n" + "AI core can not be accessed.", 5.0)
		return
	
	var bot_ability = bot.get_ability()
	
	match bot_ability:
		"repair":
			await repair_core()
		"secure":
			security_done = true
			await show_timed_dialog(
				"SecurityBot received.\n\n" +
				"execute_task() resolved to secure().\n\n" +
				"Recovery protocol authenticated.",
				5.0
			)
			await check_core_status()
		"transport":
			transport_done = true
			await show_timed_dialog(
				"TransportBot received.\n\n" +
				"execute_task() resolved to transport().\n\n" +
				"Emergency power module delivered.",
				5.0
			)
			await check_core_status()
			
func check_core_status():
	if !(repair_done and security_done and transport_done):
		return
		
	if core_online:
		return
	
	core_online = true
	MissionManager.complete_subtask("ai_core", "Wait for the robots")
	await show_timed_dialog("AI Core online.\n\n" +"All robot tasks completed.", 5.0)

	if player_nearby and !station_rebooted:
		dialogbox.show_dialog("AI Core online.\n\nPress [ENTER] to reboot the space station.", true, "AI CORE")
			
func repair_core():
	if repair_done:
		return
	
	repair_done = true
	
	repair_effect.visible = true
	repair_effect.play("repair")
	repair_sound.play()
		
	await show_timed_dialog("RepairBot received.\n\n" +"execute_task() resolved to repair().\n\n" +"Damaged AI Core circuits restored.", 5.0)
	
	if repair_effect != null:
		repair_effect.stop()
		repair_effect.visible = false
	
	await check_core_status()

func reboot_station():

	dialogbox.hide_dialog()
	
	await show_timed_dialog(
		"REBOOT INITIATED...\n\n" +
		"Loading AI Core...\n" +
		"Restoring station services...\n" +
		"Synchronizing object network...",
		5.0
	)
	if repair_effect != null:
		repair_effect.visible = true
		repair_effect.play("repair")
	if repair_sound != null:
		repair_sound.play()
	await flicker()
	await get_tree().create_timer(3.0).timeout
	if repair_effect != null:
		repair_effect.visible = false
	if repair_sound != null:
		repair_sound.stop()
	await show_timed_dialog(
		"SPACE STATION ECLIPSE-9\n\n" +
		"STATUS: ONLINE\n\n" +
		"Object communication restored.\n" +
		"All systems operational.",
		5.0
	)
	MissionManager.complete_subtask("ai_core", "Reboot space station")
	if door != null:
		door.open_door()

func is_online() -> bool:
	return core_online
	
func show_timed_dialog(text: String, duration: float):
	dialog_id += 1
	var current_id = dialog_id
	
	dialogbox.show_dialog(text)
	await get_tree().create_timer(duration).timeout
	
	if current_id == dialog_id:
		dialogbox.hide_dialog()
		
func flicker():
	if canvas_modulate == null:
		return
		
	var normal_color = Color.WHITE
	var dark_color = Color("#696969")
	
	for i in range(8):
		canvas_modulate.color = dark_color
		await get_tree().create_timer(0.08).timeout
		canvas_modulate.color = normal_color
		await get_tree().create_timer(0.12).timeout
	
	var tween = create_tween()
	tween.tween_property(canvas_modulate, "color", normal_color, 2.0)

func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		if !core_online:
			dialogbox.show_dialog("This central intelligence coordinates\nall major station systems.\n\nEvery connected OBJECT can exchange\nmessages with the AI Core through\nmethod calls.\n\nRestore the station server to regain\nfull system control.", true, "AI CORE")
		elif !station_rebooted:
			dialogbox.show_dialog("AI Core online.\n\nPress [ENTER] to reboot the space station.", true, "AI CORE")

func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
		dialogbox.hide_dialog()
