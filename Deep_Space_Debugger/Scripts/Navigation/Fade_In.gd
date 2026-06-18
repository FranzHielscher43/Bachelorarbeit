extends CanvasLayer

@export var fade_duration := 1.0
@onready var fade_rect = $FadeRect

func _ready():
	fade_rect.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
