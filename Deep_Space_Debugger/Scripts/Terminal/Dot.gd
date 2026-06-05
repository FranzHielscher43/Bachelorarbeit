extends Control

func _process(delta):
	queue_redraw()

func _draw():
	var pulse = 0.5 + sin(Time.get_ticks_msec() * 0.005) * 0.5

	draw_circle(
		size / 2,
		8,
		Color(0.082, 0.729, 0.071, pulse)
	)
