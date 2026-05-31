extends Area2D

@export var item_id := "object_1"
@onready var sprite = $Sprite2D

var original_scale : Vector2

var player_nearby := false
var is_carried := false
var current_player = null
var world = null

func _ready():
	original_scale = sprite.scale
	world = get_parent()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta):
	if player_nearby and !is_carried and Input.is_action_just_pressed("ui_accept"):
		pick_up()
	elif is_carried and Input.is_action_just_pressed("ui_accept"):
		drop()
		
	if player_nearby:
		var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.1
		sprite.scale = original_scale * pulse
		if Input.is_action_just_pressed("ui_accept"):
			sprite.scale = original_scale
	else:
		sprite.scale = original_scale

func pick_up():
	if current_player == null:
		return
	is_carried = true
	world = get_parent()
	get_parent().remove_child(self)
	current_player.add_child(self)
	position = Vector2(0, -24)

func drop():
	var drop_distance := 32
	var directions = [
		current_player.last_direction,
		Vector2.DOWN,
		Vector2.UP,
		Vector2.LEFT,
		Vector2.RIGHT
	]

	var final_position = global_position
	for dir in directions:
		var test_position = current_player.global_position + dir.normalized() * drop_distance

		if !is_position_blocked(test_position):
			final_position = test_position
			break
	is_carried = false
	current_player.remove_child(self)
	world.add_child(self)
	global_position = final_position
	
func is_position_blocked(test_position: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsPointQueryParameters2D.new()
	query.position = test_position
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var result = space_state.intersect_point(query)

	return result.size() > 0

func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		current_player = body

func _on_body_exited(body):
	if body.name == "Player" and !is_carried:
		player_nearby = false
		current_player = null
