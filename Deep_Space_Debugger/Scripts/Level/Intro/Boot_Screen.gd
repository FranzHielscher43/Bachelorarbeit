extends CanvasLayer

@onready var label = $Label
@onready var type_sound = $TypeSound
@onready var flicker = $FlickerOverlay
var label_start_position := Vector2.ZERO

var typing_speed := 0.04
var is_typing := false

func _ready():
	randomize()
	label_start_position = label.position

func _process(_delta):
	flicker.modulate.a = randf_range(0.0, 0.04)

func glitch():
	var original_text = label.text
	var glitched_chars = ["#", "@", "%", "!", "*", "/", "\\", "_"]
	
	for i in range(4):
		flicker.color = Color(
			randf_range(0.0, 0.2),
			randf_range(0.8, 1.0),
			randf_range(0.8, 1.0),
			1.0
		)
		flicker.modulate.a = randf_range(0.15,0.25)
		label.text = original_text + "\n> " + random_glitch_line(24)
		label.position = label_start_position + Vector2(randf_range(-5, 5), randf_range(-4, 4))
		await get_tree().create_timer(0.03).timeout
		flicker.modulate.a = 0.0
		label.position = label_start_position
		label.text = original_text
		await get_tree().create_timer(0.02).timeout

func random_glitch_line(length: int) -> String:
	var chars = ["#", "@", "%", "!", "*", "/", "\\", "_", "-", "0", "1"]
	var result := ""
	for i in range(length):
		result += chars.pick_random()
	return result

func clear_boot():
	label.text = ""

func typing(text: String):
	is_typing = true
	for i in text.length():
		if !is_typing:
			return
			
		label.text += text[i]
		if text[i] != " " and !type_sound.playing:
			type_sound.play()

		await get_tree().create_timer(typing_speed).timeout
	
	label.text += "\n\n"
	is_typing = false
