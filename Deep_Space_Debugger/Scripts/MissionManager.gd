# MissionManger.gd

extends Node

var mission_ui = null

func complete_mission(id: String):
	if mission_ui != null:
		mission_ui.complete_mission(id)

func complete_subtask(mission_id: String, subtask_id: String):
	if mission_ui != null:
		mission_ui.complete_subtask(mission_id, subtask_id)
