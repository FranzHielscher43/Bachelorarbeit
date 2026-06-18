extends CanvasLayer

@onready var mission_label = $Panel/MarginContainer/VBoxContainer/MissionLabel
@onready var type_sound = $Panel/MarginContainer/VBoxContainer/TypeSound
@onready var success_sound = $Panel/MarginContainer/VBoxContainer/SuccessSound
@onready var check_sound = $Panel/MarginContainer/VBoxContainer/CheckSound

@onready var panel = $Panel
@onready var vbox = $Panel/MarginContainer/VBoxContainer

@export var start_mission_id := ""

var mission_steps = [
	{"id": "tutorial", "text": "Tutorial", "done": false, "subtasks": {"Press any movement key": false, "Open menu with ESC": false, "Open the inventory with I": false, "Navigate with Up and Down": false, "Open the minimap with M": false, "Open terminal with ENTER": false, "Pick up object": false, "Drop object": false}},
	{"id": "level_01", "text": "Proceed to the power supply", "done": false, "subtasks": {"Go to the power supply": false}},
	{"id": "energy_core", "text": "Restore power supply", "done": false, "subtasks": {"Open terminal": false, "Examine energy cores": false, "Insert matching energy core": false}},
	{"id": "level_02", "text": "Go to the security center", "done": false, "subtasks": {"Use the unlocked passageway": false}},
	{"id": "security_access", "text": "Obtain security access", "done": false, "subtasks": {"Check security door": false, "Insert appropriate access module": false, "Open security terminal": false, "Request clearance": false}},
	{"id": "level_03", "text": "Proceed to the communications center", "done": false, "subtasks": {"Open security door": false}},
	{"id": "robotics", "text": "Repair the communication relay", "done": false, "subtasks": {"Open terminal": false, "Select & send repair robot": false, "Select & send transport robot": false, "Select & send security robot": false}},
	{"id": "level_04", "text": "Go to the next area", "done": false, "subtasks": {}},
	{"id": "communication", "text": "Activate communication system", "done": false, "subtasks": {"Send navigation signal": false, "Send life support signal": false, "Send security channel signal": false}},
	{"id": "ai_core", "text": "Reboot AI core system", "done": false, "subtasks": {"Open terminal": false, "Activate core method": false}}
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
	else:
		await update_mission_size()

func complete_subtask(mission_id: String, subtask_id: String):
	for i in range(mission_steps.size()):
		var mission = mission_steps[i]
		if mission["id"] == mission_id:
			if mission["subtasks"].has(subtask_id):
				mission["subtasks"][subtask_id] = true
				if i != current_mission_index:
					return
				check_sound.play()
				await show_next_subtask_typed()
				var all_done := true
				for value in mission["subtasks"].values():
					if value == false:
						all_done = false
				if all_done:
					await get_tree().create_timer(3.0).timeout
					complete_mission(mission_id)
				return

func update_mission_display():

	var mission = mission_steps[current_mission_index]
	var text := ""
	text += "□ " + mission["text"] + "\n"
	var show_next := true
	for subtask_id in mission["subtasks"].keys():
		var done = mission["subtasks"][subtask_id]
		if done:
			text += "   ☑ " + subtask_id + "\n"
		elif show_next:
			text += "   □ " + subtask_id + "\n"
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
		mission_label.text = "☑ " + mission["text"]
		await update_mission_size()
	else:
		var preview_text = "□ " + mission["text"]
		mission_label.text = preview_text
		await update_mission_size()
		mission_label.text = "□ "
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
		update_mission_display()
		
func are_all_subtasks_done(mission) -> bool:
	for value in mission["subtasks"].values():
		if value == false:
			return false
	return true
	
func type_text(text: String):
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
	for char in text:
		if !is_typing:
			return
		mission_label.text += char
		if char != " " and !type_sound.playing:
			type_sound.play()
		await get_tree().create_timer(typing_speed).timeout
		
	is_typing = false
	await update_mission_size()
	
func show_full_mission_typed():

	if current_mission_index >= mission_steps.size():
		return
	var mission = mission_steps[current_mission_index]
	var full_text := ""
	full_text += "□  " + mission["text"] + "\n"
	for subtask_id in mission["subtasks"].keys():
		if !mission["subtasks"][subtask_id]:
			full_text += "   □  " + subtask_id + "\n"
			break
	mission_label.text = full_text
	await update_mission_size()
	mission_label.text = ""
	await type_text(full_text)
	
func show_next_subtask_typed():
	var mission = mission_steps[current_mission_index]

	var completed_text := ""
	var next_subtask := ""

	for subtask_id in mission["subtasks"].keys():
		if mission["subtasks"][subtask_id]:
			completed_text += "   ☑ " + subtask_id + "\n"
		else:
			next_subtask = subtask_id
			break

	var full_preview = "□  " + mission["text"] + "\n" + completed_text

	if next_subtask != "":
		full_preview += "   □ " + next_subtask + "\n"

	mission_label.modulate.a = 0.0
	mission_label.text = full_preview
	await update_mission_size()
	
	mission_label.text = "□ " + mission["text"] + "\n" + completed_text
	mission_label.modulate.a = 1.0

	if next_subtask != "":
		await type_text("   □  " + next_subtask + "\n")
	
func update_mission_size():
	await get_tree().process_frame

	var min_height = 40
	var padding = 20
	
	var needed_height = vbox.get_combined_minimum_size().y + padding
	var new_height = max(min_height, needed_height)

	panel.size.y = new_height
	panel.custom_minimum_size.y = new_height
