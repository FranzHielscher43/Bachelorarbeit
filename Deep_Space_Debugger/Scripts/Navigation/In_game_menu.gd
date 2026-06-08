extends CanvasLayer

@onready var continue_button = $Control/VBoxContainer/ContinueButton
@onready var main_menu_button = $Control/VBoxContainer/MainMenuButton
@onready var quit_button = $Control/VBoxContainer/QuitButton

@onready var dialog_box = $"../Dialogbox"

@onready var click_sound = $ClickSound
@onready var hover_sound = $HoverSound
@onready var menu_sound = $MenuAmbient

var first_click := true

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	continue_button.focus_entered.connect(_on_button_hover)
	main_menu_button.focus_entered.connect(_on_button_hover)
	quit_button.focus_entered.connect(_on_button_hover)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		
func toggle_pause():
	visible = !visible
	get_tree().paused = visible
	
	if visible:
		dialog_box.hide_dialog()
		menu_sound.play()
		continue_button.grab_focus()
	else:
		menu_sound.stop()

func continue_pressed():
	click_sound.play()
	await click_sound.finished
	menu_sound.stop()
	toggle_pause()
	
func main_menu_pressed():
	get_tree().paused = false
	click_sound.play()
	await click_sound.finished
	get_tree().change_scene_to_file("res://Scenes/Navigation/MainMenu.tscn")
	
func quit_pressed():
	click_sound.play()
	await click_sound.finished
	get_tree().quit()
	
func _on_button_hover():
	if first_click:
		first_click = false
		return
	hover_sound.play()
