extends Robot
class_name RepairBot

func get_bot_name() -> String:
	return "RepairBot"
	
func get_ability() -> String:
	return "repair"
	
func execute_task(target):
	if target != null and target.has_method("receive_robot_task"):
		target.receive_robot_task(self)
		await get_tree().create_timer(2.5).timeout
		return_home()
		return
	
	if target != null and target.has_method("repair"):
		target.repair()
		await get_tree().create_timer(2.5).timeout
		return_home()
