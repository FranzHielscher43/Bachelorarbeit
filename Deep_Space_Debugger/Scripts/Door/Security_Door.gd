extends "res://Scripts/Door/Door.gd"

@onready var dialog_box = $"../../Dialogbox"
var access_granted := false
@export_multiline var denied_text := "> Direct access denied. <\n\nThis system is ENCAPSULATED.\nUse the security console."

func interact():
	if access_granted:
		open_door()
		MissionManager.complete_subtask(
			"level_03",
			"Open security door"
		)
	else:
		MissionManager.complete_subtask(
			"security_access",
			"Check security door"
		)
		dialog_box.show_dialog(denied_text)
		await get_tree().create_timer(7.0).timeout
		dialog_box.hide_dialog()

func grant_access():
	access_granted = true
	dialog_box.show_dialog("Secrutiy clearance received.")
	await get_tree().create_timer(4.0).timeout
	dialog_box.hide_dialog()

func unlock_by_security_bot():
	grant_access()
	open_door()
