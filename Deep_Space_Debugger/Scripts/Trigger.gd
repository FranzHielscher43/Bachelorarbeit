extends Area2D

@export_multiline var dialog_text := ""

@onready var dialog_box = $"../Dialogbox"

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		dialog_box.show_dialog(dialog_text)

func _on_body_exited(body):
	if body.name == "Player":
		dialog_box.hide_dialog()
