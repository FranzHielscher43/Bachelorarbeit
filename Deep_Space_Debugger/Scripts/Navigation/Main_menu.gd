extends Control

@onready var main_container = $MainContainer
@onready var creator_container = $CreatorContainer

@onready var start_button = $MainContainer/StartButton
@onready var creator_button = $MainContainer/CreatorButton
@onready var quit_button = $MainContainer/QuitButton

@onready var back_button = $CreatorContainer/BackButton

@onready var click_sound = $ClickSound
@onready var hover_sound = $HoverSound

func _ready():
	creator_container.visible = false
	main_container.visible = true
	
	start_button.grab_focus()
	start_button.focus_entered.connect(_on_button_hover)
	creator_button.focus_entered.connect(_on_button_hover)
	quit_button.focus_entered.connect(_on_button_hover)

func _on_start_button_pressed():
	click_sound.play()
	await click_sound.finished
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

func _on_quit_button_pressed():
	click_sound.play()
	await click_sound.finished
	get_tree().quit()
	
func _on_creator_button_pressed():
	click_sound.play()
	await click_sound.finished
	main_container.visible = false
	creator_container.visible = true
	
	back_button.grab_focus()
	
func _on_back_button_pressed():
	click_sound.play()
	await  click_sound.finished
	creator_container.visible = false
	main_container.visible = true
	
	start_button.grab_focus()
	
func _on_button_hover():
	hover_sound.play()
