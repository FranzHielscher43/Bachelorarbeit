extends CanvasLayer

@onready var mission_label = $Panel/MarginContainer/VBoxContainer/MissionLabel
@onready var type_sound = $Panel/MarginContainer/VBoxContainer/TypeSound
@onready var success_sound = $Panel/MarginContainer/VBoxContainer/SuccessSound
@onready var check_sound = $Panel/MarginContainer/VBoxContainer/CheckSound

@onready var panel = $Panel
@onready var vbox = $Panel/MarginContainer/VBoxContainer

var mission_steps = [
	{"id": "start_robot", "text": "Roboter starten", "done": false, "subtasks": {"Terminal öffnen": false, "Startknopf betätigen": false}},
	{"id": "open_door", "text": "Tür öffnen", "done": false, "subtasks": {"Knopf drücken": false}},
	{"id": "open_lab", "text": "Zugang zum Labor", "done":false, "subtasks": {"Korrektes Objekt platzieren": false}}
]

var current_mission_index := 0
var typing_speed := 0.03
var is_typing := false

func _ready():
	MissionManager.mission_ui = self
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
	
	type_message("Empfange nächste Mission...")
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
		success_sound.play()
		mission_label.text = "Alle Missionen erfolgreich abgeschlossen!"
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
				update_mission_display()
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
	for subtask_id in mission["subtasks"].keys():
		var done = mission["subtasks"][subtask_id]
		var symbol = "☑" if done else "□ "
		text += "     " + symbol + " " + subtask_id + "\n"
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
			type_text(mission["text"])
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
	full_text += "□ " + mission["text"] + "\n"
	for subtask_id in mission["subtasks"].keys():
		var done = mission["subtasks"][subtask_id]
		var symbol = "☑" if done else "□ "
		full_text += "     " + symbol + " " + subtask_id + "\n"
	mission_label.text = full_text
	await update_mission_size()
	mission_label.text = ""
	await type_text(full_text)
	
func update_mission_size():
	await get_tree().process_frame

	var min_height = 40
	var padding = 20
	
	var needed_height = vbox.get_combined_minimum_size().y + padding
	var new_height = max(min_height, needed_height)

	panel.size.y = new_height
	panel.custom_minimum_size.y = new_height
