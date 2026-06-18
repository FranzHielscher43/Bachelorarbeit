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
		target.receive_robot_task(self)
		secure_sound.play()
		await get_tree().create_timer(2.5).timeout
		return_home()
		return
	
	if target != null and target.has_method("unlock_by_security_bot"):
		target.unlock_by_security_bot()
		secure_sound.play()
		await get_tree().create_timer(2.5).timeout
		return_home()
		return
		
	dialogbox.show_dialog("SecurityBot.scan() executed.\nDoes not require security clearance.\nBot lacks a matching method().")
	await get_tree().create_timer(5.0).timeout
	dialogbox.hide_dialog()
	return_home()
