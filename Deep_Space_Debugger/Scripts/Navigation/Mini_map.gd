extends Control

@export var cell_size := 48
@export var map_scale := 3
@export var reveal_radius := 3

var player = null
var tilemap = null
var discovered_cells := {}

var target = null
var targets: Array = []

func _ready():
	custom_minimum_size = Vector2(250, 250)
	size = Vector2(250, 250)
	player = get_tree().get_first_node_in_group("Player")

func _input(event):
	if event.is_action_pressed("map"):
		visible = !visible

func _process(_delta):
	if player == null:
		return

	reveal_around_player()
	queue_redraw()

func reveal_around_player():
	var player_cell = Vector2i(
		floor(player.global_position.x / cell_size),
		floor(player.global_position.y / cell_size)
	)

	for x in range(-reveal_radius, reveal_radius + 1):
		for y in range(-reveal_radius, reveal_radius + 1):
			var cell = player_cell + Vector2i(x, y)
			discovered_cells[cell] = true

func _draw():
	if player == null:
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.08, 0.85))

	for x in range(0, int(size.x), 16):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.1, 0.4, 0.6, 0.25))

	for y in range(0, int(size.y), 16):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.1, 0.4, 0.6, 0.25))

	var center = size / 2

	var player_cell = Vector2i(
		floor(player.global_position.x / cell_size),
		floor(player.global_position.y / cell_size)
	)

	for cell in discovered_cells.keys():
		var relative_cell = cell - player_cell
		var pos = center + Vector2(relative_cell.x, relative_cell.y) * map_scale
		if pos.x >= 0 and pos.x <= size.x and pos.y >= 0 and pos.y <= size.y:
			draw_rect(Rect2(pos, Vector2(map_scale, map_scale)),Color(0.1, 0.7, 1.0, 0.75))

	draw_circle(center, 4, Color.WHITE)
	draw_circle(center, 7, Color(0.2, 0.8, 1.0, 0.4))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#10677c"), false, 3)

	for current_target in targets:
		if current_target == null:
			continue
			
		var direction = current_target.global_position - player.global_position
		var target_pos = center + direction / cell_size * map_scale
		var margin := 12.0
		
		target_pos.x = clamp(target_pos.x, margin, size.x - margin)
		target_pos.y = clamp(target_pos.y, margin, size.y - margin)
		
		draw_circle(target_pos, 5, Color("#15ba12"))
		draw_circle(target_pos, 9, Color(0.1, 1.0, 0.2, 0.35))

func set_target(new_target):
	if new_target == null:
		targets = []
	else:
		targets = [new_target]
	queue_redraw()
	
func set_targets(new_targets: Array):
	targets = new_targets
	queue_redraw()
