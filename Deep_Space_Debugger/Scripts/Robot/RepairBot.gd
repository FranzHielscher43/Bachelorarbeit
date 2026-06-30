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
		MissionManager.complete_subtask("repair", "Escort repair robot")
		var terminal = get_tree().get_first_node_in_group("Terminal")
		if terminal != null:
			terminal.repair_job_done = true
			terminal.update_robot_button_locks()
		return_home()
