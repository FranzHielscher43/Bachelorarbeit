extends Area2D
class_name AICore

@onready var dialogbox = $"../Dialogbox"
var dialog_id := 0
var communication_online := false

var repair_done := false
var security_done := false
var transport_done := false

var core_online := false

func activate_communication():
	communication_online = true
	dialogbox.show_dialog("Communication server online.\n" + "AI core can be accessed.")
	await get_tree().create_timer(5.0).timeout
	dialogbox.hide_dialog()

func receive_robot_task(bot):
	if !communication_online:
		await show_timed_dialog("Communication server offline.\n" + "AI core can not be accessed.", 5.0)
		return
	
	var bot_name = bot.get_bot_name()
	var bot_ability = bot.get_ability()
	
	await show_timed_dialog("Unit received:\n" + bot_name + "\n\n" + "United call:\n" + "execute_task()\n\n" + "Specialized ability:\n" + bot_ability, 5.0)
	
	match bot_ability:
		"repair":
			MissionManager.complete_subtask("ai_core", "Use repair bot")
		"secure":
			MissionManager.complete_subtask("ai_core", "Use security bot")
		"transport":
			MissionManager.complete_subtask("ai_core", "Use transport bot")

func check_core_status():
	if repair_done and security_done and transport_done and !core_online:
		core_online = true
		MissionManager.complete_subtask("ai_core", "Activate core method")
		await show_timed_dialog("AI core rebooted.\n\n" + "Used POLYMORPHISM:\n" + "A united method call produced different behavior.", 5.0)
	else: 
		await show_timed_dialog("Execution of common method necessary.", 5.0)
	
func is_online() -> bool:
	return core_online
	
func show_timed_dialog(text: String, duration: float):
	dialog_id += 1
	var current_id = dialog_id
	
	dialogbox.show_dialog(text)
	await get_tree().create_timer(duration).timeout
	
	if current_id == dialog_id:
		dialogbox.hide_dialog()
