extends Robot
class_name SecurityBot

@onready var dialogbox = $"../Dialogbox"
@onready var secure_sound = $SecureSound

func get_bot_name() -> String:
	return "SecurityBot"
	
func get_ability() -> String:
	return "secure"
	
func execute_task(target):
	if target != null and target.has_method("receive_robot_task"):
		if secure_sound != null:
			secure_sound.play()
		await target.receive_robot_task(self)
		return
	
	if target != null and target.has_method("unlock_by_security_bot"):
		target.unlock_by_security_bot()
		secure_sound.play()
		await get_tree().create_timer(2.5).timeout
		MissionManager.complete_subtask("secure", "Escort security robot")
		var terminal = get_tree().get_first_node_in_group("Terminal")
		if terminal != null:
			terminal.security_job_done = true
			terminal.update_robot_button_locks()
		return_home()
		return
		
	dialogbox.show_dialog("SecurityBot.scan() executed.\nDoes not require security clearance.\nBot lacks a matching method().")
	await get_tree().create_timer(5.0).timeout
	dialogbox.hide_dialog()
	return_home()
