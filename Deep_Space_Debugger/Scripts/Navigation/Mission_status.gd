extends CanvasLayer

@onready var mission_label = $Panel/MarginContainer/VBoxContainer/MissionLabel
@onready var type_sound = $Panel/MarginContainer/VBoxContainer/TypeSound
@onready var success_sound = $Panel/MarginContainer/VBoxContainer/SuccessSound
@onready var check_sound = $Panel/MarginContainer/VBoxContainer/CheckSound

@onready var panel = $Panel
@onready var vbox = $Panel/MarginContainer/VBoxContainer

@export var start_mission_id := ""
@export var minimap_path : NodePath
@onready var minimap = get_node_or_null(minimap_path)

var is_updating_mission := false
var pending_refresh := false

var mission_steps = [
	{
		"id": "tutorial",
		"text": "Tutorial",
		"done": false,
		"subtasks": [
			{"text": "Press any movement key [WASD]", "done": false, "target": ""},
			{"text": "Open menu with [ESC]", "done": false, "target": ""},
			{"text": "Open inventory with [I]", "done": false, "target": ""},
			{"text": "Navigate inventory with [UP/DOWN]", "done": false, "target": ""},
			{"text": "Open/Close minimap with [M]", "done": false, "target": ""},
			{"text": "Find & open hologram with [ENTER]", "done": false, "target": "Hologram"},
			{"text": "Find & open terminal with [ENTER]", "done": false, "target": "TerminalObject"},
			{"text": "Pick up object [ENTER]", "done": false, "target": "TutorialObject"},
			{"text": "Drop object [I]+[UP/DOWN]+[ENTER]", "done": false, "target": ""}
		]
	},
	{
		"id": "level_01",
		"text": "Proceed to the power supply",
		"done": false,
		"subtasks": [
			{"text": "Go to the power supply", "done": false, "target": "LevelTransition"}
		]
	},
	{
		"id": "energy_core",
		"text": "Restore power supply",
		"done": false,
		"subtasks": [
			{"text": "Open terminal & examine error", "done": false, "target": "TerminalObject"},
			{"text": "Examine energy core", "done": false, "target": "EnergyCore_Broken"},
			{"text": "Find & insert matching energy core", "done": false, "target": ["EnergyCore_A", "EnergyCore_B", "EnergyCore_C"]}
		]
	},
	{
		"id": "level_02",
		"text": "Go to the security center",
		"done": false,
		"subtasks": [
			{"text": "Use the unlocked passageway", "done": false, "target": "LevelTransition"}
		]
	},
	{
		"id": "security_access",
		"text": "Obtain security access",
		"done": false,
		"subtasks": [
			{"text": "Check security door", "done": false, "target": "CheckArea"},
			{"text": "Check terminal & examine problem", "done": false, "target": "TerminalObject"},
			{"text": "Insert appropriate access module", "done": false, "target": ["AccessModule_A", "AccessModule_B", "AccessModule_C"]},
			{"text": "Request clearance in terminal", "done": false, "target": "TerminalObject"}
		]
	},
	{
		"id": "level_03",
		"text": "Proceed to the communications center",
		"done": false,
		"subtasks": [
			{"text": "Open security door", "done": false, "target": "CheckArea"},
			{"text": "Use the unlocked passageway", "done": false, "target": "LevelTransition"}
		]
	},
	{
		"id": "repair",
		"text": "Repair the communication relay",
		"done": false,
		"subtasks": [
			{"text": "Open terminal & examine problem", "done": false, "target": "TerminalObject"},
			{"text": "Select & send repair robot", "done": false, "target": "TerminalObject"},
			{"text": "Escort repair robot", "done": false, "target": "RepairBot"}
		]
	},
	{
		"id": "transport",
		"text": "Open the locked door",
		"done": false,
		"subtasks": [
			{"text": "Select & send transport robot", "done": false, "target": "TerminalObject"},
			{"text": "Wait for the transport robot", "done": false, "target": "TransportBot"}
		]
	},
	{
		"id": "secure",
		"text": "Access the security door",
		"done": false,
		"subtasks": [
			{"text": "Select & send security robot", "done": false, "target": "TerminalObject"},
			{"text": "Escort security robot", "done": false, "target": "SecurityBot"}
		]
	},
	{
		"id": "level_04",
		"text": "Proceed to the Station command center",
		"done": false,
		"subtasks": [
			{"text": "Use the elevator", "done": false, "target": "LevelTransition"}
		]
	},
	{
		"id": "communication",
		"text": "Activate station server",
		"done": false,
		"subtasks": [
			{"text": "Send navigation signal", "done": false, "target": "SignalSwitch_Navigation"},
			{"text": "Send life support signal", "done": false, "target": "SignalSwitch_LifeSupport"},
			{"text": "Send security channel signal", "done": false, "target": "SignalSwitch_Security"}
		]
	},
	{
		"id": "ai_core",
		"text": "Reboot AI core system",
		"done": false,
		"subtasks": [
			{"text": "Open terminal & find method", "done": false, "target": "TerminalObject"},
			{"text": "Activate core method in terminal", "done": false, "target": "TerminalObject"},
			{"text": "Wait for the robots", "done": false, "target": "aiCore"},
			{"text": "Reboot space station at AI core", "done": false, "target": "aiCore"}
		]
	},
	{
		"id": "end",
		"text": "Leave the station command center",
		"done": false,
		"subtasks": [
			{"text": "Go to the exit in robotics area", "done": false, "target": "LevelTransition"}
		]
	}
]

var current_mission_index := 0
var typing_speed := 0.03
var is_typing := false

func _ready():
	MissionManager.mission_ui = self
	for i in range(mission_steps.size()):
		if mission_steps[i]["id"] == start_mission_id:
			current_mission_index = i
			break
			
	panel.size.y = 60
	await show_full_mission_typed()
	update_minimap_target()

func complete_mission(id: String):
	if current_mission_index >= mission_steps.size():
		return
		
	var mission = mission_steps[current_mission_index]
	
	if mission["id"] != id:
		return
	
	mission["done"] = true
	show_current_mission(false)
	success_sound.play()
	await get_tree().create_timer(2.0).timeout
	
	await type_message("Receive next mission...")
	await get_tree().create_timer(3.0).timeout
	
	current_mission_index += 1
	
	if current_mission_index < mission_steps.size():
		check_and_complete_current_mission()
		if mission_steps[current_mission_index]["done"]:
			await get_tree().create_timer(2.0).timeout
			complete_mission(mission_steps[current_mission_index]["id"])
		else:
			await show_full_mission_typed()
			update_minimap_target()
	else:
		await update_mission_size()
		update_minimap_target()

func complete_subtask(mission_id: String, subtask_id: String):
	for i in range(mission_steps.size()):
		var mission = mission_steps[i]

		if mission["id"] != mission_id:
			continue

		for subtask in mission["subtasks"]:
			if subtask["text"] == subtask_id:
				if subtask["done"]:
					return

				subtask["done"] = true

				if i != current_mission_index:
					return

				if is_updating_mission:
					pending_refresh = true
					return

				is_updating_mission = true

				check_sound.play()
				await show_next_subtask_typed()
				update_minimap_target()

				if are_all_subtasks_done(mission):
					await get_tree().create_timer(1.0).timeout
					await complete_mission(mission_id)

				is_updating_mission = false

				if pending_refresh:
					pending_refresh = false
					await update_mission_display()
					update_minimap_target()
					
					if are_all_subtasks_done(mission):
						await get_tree().create_timer(1.0).timeout
						await complete_mission(mission_id)

				return

func update_mission_display():
	var mission = mission_steps[current_mission_index]
	var text := ""
	text += "[ ] " + mission["text"] + "\n"
	
	var show_next := true
	
	for subtask in mission["subtasks"]:
		if subtask["done"]:
			text += "   [X] " + subtask["text"] + "\n"
		elif show_next:
			text += "   [ ] " + subtask["text"] + "\n"
			show_next = false
			
	mission_label.text = text
	await update_mission_size()

func show_current_mission(use_typing: bool):
	if current_mission_index >= mission_steps.size():
		return
	
	var mission = mission_steps[current_mission_index]
	
	is_typing = false
	type_sound.stop()
	
	if mission["done"]:
		mission_label.text = "[X] " + mission["text"]
		await update_mission_size()
	else:
		var preview_text = "[ ]  " + mission["text"]
		mission_label.text = preview_text
		await update_mission_size()
		mission_label.text = "[ ]  "
		if use_typing:
			await type_text(mission["text"])
		else:
			mission_label.text += mission["text"]
			await update_mission_size()
			
	await update_mission_size()

func check_and_complete_current_mission():
	var mission = mission_steps[current_mission_index]
	if are_all_subtasks_done(mission):
		mission["done"] = true
		await update_mission_display()
		
func are_all_subtasks_done(mission) -> bool:
	for subtask in mission["subtasks"]:
		if !subtask["done"]:
			return false
	return true
	
func type_text(text: String):
	is_typing = false
	await get_tree().process_frame
	is_typing = true
	for i in text.length():
		if !is_typing:
			return
		mission_label.text += text[i]

		if text[i] != " " and !type_sound.playing:
			type_sound.play()
		await get_tree().create_timer(typing_speed).timeout
	
	is_typing = false
	await update_mission_size()

func type_message(text: String):
	is_typing = true
	mission_label.text = ""
	for chars in text:
		if !is_typing:
			return
		mission_label.text += chars
		if chars != " " and !type_sound.playing:
			type_sound.play()
		await get_tree().create_timer(typing_speed).timeout
		
	is_typing = false
	await update_mission_size()
	
func show_full_mission_typed():
	if current_mission_index >= mission_steps.size():
		return
		
	var mission = mission_steps[current_mission_index]
	var full_text := ""
	
	full_text += "[ ] " + mission["text"] + "\n"
	
	for subtask in mission["subtasks"]:
		if !subtask["done"]:
			full_text += "   [ ] " + subtask["text"] + "\n"
			break
			
	mission_label.text = full_text
	await update_mission_size()
	
	mission_label.text = ""
	await type_text(full_text)
	
func show_next_subtask_typed():
	var mission = mission_steps[current_mission_index]

	var completed_text := ""
	var next_subtask := ""

	for subtask in mission["subtasks"]:
		if subtask["done"]:
			completed_text += "   [X] " + subtask["text"] + "\n"
		else:
			next_subtask = subtask["text"]
			break

	var full_preview = "[ ] " + mission["text"] + "\n" + completed_text

	if next_subtask != "":
		full_preview += "   [ ] " + next_subtask + "\n"

	mission_label.modulate.a = 0.0
	mission_label.text = full_preview
	await update_mission_size()
	
	mission_label.text = "[ ] " + mission["text"] + "\n" + completed_text
	mission_label.modulate.a = 1.0

	if next_subtask != "":
		await type_text("   [ ] " + next_subtask + "\n")
	
func update_mission_size():
	await get_tree().process_frame

	var min_height = 40
	var padding = 20
	
	var needed_height = vbox.get_combined_minimum_size().y + padding
	var new_height = max(min_height, needed_height)

	panel.size.y = new_height
	panel.custom_minimum_size.y = new_height

func update_minimap_target():
	if minimap == null:
		return
		
	if current_mission_index >= mission_steps.size():
		minimap.set_targets([])
		return
	
	var mission = mission_steps[current_mission_index]
	
	for subtask in mission["subtasks"]:
		if !subtask["done"]:
			var target = subtask.get("target", null)
			
			if target is Array:
				var target_nodes := []
				
				for target_name in target:
					var target_node = get_tree().current_scene.find_child(target_name, true, false)
					if target_node != null:
						target_nodes.append(target_node)
				
				minimap.set_targets(target_nodes)
				return
			
			if target == null or target == "":
				minimap.set_targets([])
				return
			
			var target_node = get_tree().current_scene.find_child(target, true, false)
			
			if target_node != null:
				minimap.set_targets([target_node])
			else:
				minimap.set_targets([])
			
			return
	
	minimap.set_targets([])
