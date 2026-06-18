extends Node2D

var repaired := false
@onready var dialogbox = $"../Dialogbox"
@onready var repair_effect = $RepairEffect
@onready var repair_sound = $RepairSound
@onready var sprite = $RepairEffect

func repair():
	if repaired:
		return
	
	repaired = true
	
	repair_sound.play()
	repair_effect.visible = true
	repair_effect.play("repair")
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.GRAY, 1.0)
	dialogbox.show_dialog("Repair successfull.\nRepairBot.repair() was executed.")
	MissionManager.complete_subtask("robotics", "Send repair robot")
	await get_tree().create_timer(5.0).timeout
	repair_effect.stop()
	repair_effect.visible = false
	dialogbox.hide_dialog()

func is_repaired() -> bool:
	return repaired
