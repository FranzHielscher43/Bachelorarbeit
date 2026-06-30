extends Area2D
class_name AICore

@onready var dialogbox = $"../Dialogbox"
var dialog_id := 0
var communication_online := false

var repair_done := false
var security_done := false
var transport_done := false

@export var door_path : NodePath
@onready var door = get_node_or_null(door_path)

@onready var repair_effect = $RepairEffect
@onready var repair_sound = $RepairSound

var core_online := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

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
			MissionManager.complete_subtask("ai_core", "Use repair bot")
			await repair_core()
		"secure":
			MissionManager.complete_subtask("ai_core", "Use security bot")
			security_done = true
			await show_timed_dialog(
				"SecurityBot received.\n\n" +
				"execute_task() resolved to secure().\n\n" +
				"Recovery protocol authenticated.",
				5.0
			)
			await check_core_status()
		"transport":
			MissionManager.complete_subtask("ai_core", "Use transport bot")
			transport_done = true
			await show_timed_dialog(
				"TransportBot received.\n\n" +
				"execute_task() resolved to transport().\n\n" +
				"Emergency power module delivered.",
				5.0
			)
			await check_core_status()

func check_core_status():
	if repair_done and security_done and transport_done and !core_online:
		core_online = true
		MissionManager.complete_subtask("ai_core", "Activate core method")
		await show_timed_dialog("AI core rebooted.\n\n" + "Used POLYMORPHISM:\n" + "A united method call produced different behavior.", 5.0)
		await get_tree().create_timer(5.0).timeout
		await show_timed_dialog("Exit door opened in the robot area.", 5.0)
		door.open_door()
	else: 
		await show_timed_dialog("Execution of common method necessary.", 5.0)

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

func is_online() -> bool:
	return core_online
	
func show_timed_dialog(text: String, duration: float):
	dialog_id += 1
	var current_id = dialog_id
	
	dialogbox.show_dialog(text)
	await get_tree().create_timer(duration).timeout
	
	if current_id == dialog_id:
		dialogbox.hide_dialog()

func _on_body_entered(body):
	if body.name == "Player":
		dialogbox.show_dialog("This central intelligence coordinates\nall major station systems.\n\nEvery connected OBJECT can exchange\nmessages with the AI Core through\nmethod calls.\n\nRestore the station server to regain\nfull system control.", true, "AI CORE")
	
func _on_body_exited(body):
	if body.name == "Player":
		dialogbox.hide_dialog()
