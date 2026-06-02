extends CanvasLayer

@onready var panel = $Panel
@onready var label = $Panel/MarginContainer/Label

var full_text := ""
var current_index := 0
var typing_speed := 0.03

func _ready():
	hide_dialog()

func show_dialog(text: String):
	full_text = text
	current_index = 0 
	label.text = ""
	panel.visible = true

	type_text()
	panel.modulate = Color.WHITE

func hide_dialog():
	panel.visible = false
	label.text = ""
	
func type_text():
	while current_index < full_text.length():
		label.text += full_text[current_index]
		current_index += 1
		await get_tree().create_timer(typing_speed).timeout
		update_dialog_size()
	
func update_dialog_size():
	var min_height = 100
	var padding = 40
	
	var needed_height = label.get_minimum_size().y + padding
	panel.size.y = max(min_height, needed_height)
