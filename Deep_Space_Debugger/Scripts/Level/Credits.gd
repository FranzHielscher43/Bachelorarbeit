extends Control

@onready var color_rect = $ColorRect
@onready var label = $RichTextLabel
@onready var audio = $CreditsAudio
@export var scroll_speed := 50
@export var start_delay := 1.0

func _enter_tree():
	RenderingServer.set_default_clear_color(Color.BLACK)

func _ready():
	color_rect.color = Color.BLACK
	color_rect.modulate.a = 1.0
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.size = get_viewport().get_visible_rect().size
	
	if audio:
		audio.play()
		
	label.position.y = get_viewport().get_visible_rect().size.y 
	await get_tree().create_timer(start_delay).timeout
	set_process(true)
	
func _process(delta):
	label.position.y -= scroll_speed * delta
	if label.position.y + label.size.y < 0:
		color_rect.modulate.a = 1.0
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://Scenes/Navigation/MainMenu.tscn")
