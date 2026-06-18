extends CanvasLayer

@onready var panel = $Panel
@onready var vbox = $Panel/MarginContainer/VBoxContainer
@onready var label = $Panel/MarginContainer/VBoxContainer/Label
@onready var type_sound = $Panel/MarginContainer/VBoxContainer/TypeSound

var full_text := ""
var current_index := 0
var typing_speed := 0.03
var is_typing := false

var dialog_id := 0

func _ready():
	hide_dialog()

func show_dialog(text: String, use_typing := true):
	full_text = text
	current_index = 0 
	
	label.text = full_text
	update_dialog_size()
	label.text = ""
	
	panel.visible = true
	is_typing = true
	
	if use_typing:
		type_text()
	else:
		label.text = full_text
		update_dialog_size()
		
	panel.modulate = Color.WHITE

func hide_dialog():
	is_typing = false
	type_sound.stop()
	panel.visible = false
	label.text = ""
	
func type_text():
	while is_typing and current_index < full_text.length():
		var character = full_text[current_index]
		label.text += character
		if character != " " and !type_sound.playing:
			type_sound.play()
		current_index += 1
		await get_tree().create_timer(typing_speed).timeout
	update_dialog_size()
	
func update_dialog_size():
	var min_height = 60
	var padding = 40
	
	var needed_height = vbox.get_combined_minimum_size().y + padding
	var new_height = max(min_height, needed_height)
	
	panel.size.y = new_height
	panel.custom_minimum_size.y = new_height
	
func show_timed_dialog(text: String, duration: float):
	dialog_id += 1
	var current_id = dialog_id
	
	show_dialog(text)
	await get_tree().create_timer(duration).timeout
	
	if current_id == dialog_id:
		hide_dialog()
