extends CharacterBody2D
class_name Robot

@export var speed := 60
@onready var sprite = $AnimatedSprite2D

var direction := Vector2.ZERO
var player_nearby := false
var player = null
var is_active := false

var start_position := Vector2.ZERO
var returning_home := false
var moving_to_target := false
var target_position := Vector2.ZERO
var task_target = null

@onready var start_sound = $"StartSound"
@onready var walk_sound = $WalkingSound
@onready var hit_sound = $HitSound

@export var route_points_parent : Node2D

var route_points := []
var return_points := []
var current_return_index := 0
var current_route_index := 0

@export var require_player_nearby := true
@export var max_player_distance := 120
@export var escort_player_path : NodePath
@export var wait_after_task := 0.0
@onready var escort_player = get_node_or_null(escort_player_path)

func _ready():
	start_position = global_position
	direction = Vector2.ZERO
	sprite.play("walk_down")
	walk_sound.stop()
	$Timer.timeout.connect(_on_timer_timeout)
	$PlayerDetection.body_entered.connect(_on_detection_entered)
	$PlayerDetection.body_exited.connect(_on_detection_exited)
	
func _physics_process(delta):
	if !is_active:
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO)
		return
		
	if returning_home:
		var to_home = target_position - global_position
	
		if to_home.length() < 8:
			velocity = Vector2.ZERO
			global_position = target_position
			move_and_slide()
			update_animation(Vector2.ZERO)

			current_return_index += 1

			if current_return_index < return_points.size():
				target_position = return_points[current_return_index]
				return

			returning_home = false
			is_active = false
			walk_sound.stop()
			return

		direction = to_home.normalized()
		velocity = direction * speed
		move_and_slide()
		update_animation(direction)
		return
		
	if moving_to_target:
		if require_player_nearby and escort_player != null:
			var distance = global_position.distance_to(escort_player.global_position)

			if distance > max_player_distance:
				velocity = Vector2.ZERO
				update_animation(Vector2.ZERO)
				walk_sound.stop()
				return

			if !walk_sound.playing:
				walk_sound.play()

		var to_target = target_position - global_position

		if to_target.length() < 8:
			velocity = Vector2.ZERO
			global_position = target_position
			move_and_slide()
			update_animation(Vector2.ZERO)

			current_route_index += 1

			if current_route_index < route_points.size():
				target_position = route_points[current_route_index]
				return

			moving_to_target = false
			is_active = false
			walk_sound.stop()
			await execute_task(task_target)
			if wait_after_task > 0:
				await get_tree().create_timer(wait_after_task).timeout
				
			return_home()
			return

		direction = to_target.normalized()
		velocity = direction * speed
		move_and_slide()
		update_animation(direction)
		return
	
	if player_nearby and player != null:
		direction = (global_position - player.global_position).normalized()
	
	velocity = direction * speed
	move_and_slide()
	
	if is_on_wall():
		choose_random_direction()
	
	update_animation(direction)

func start_robot():
	if is_active:
		return
	
	is_active = true
	start_sound.play()
	await get_tree().create_timer(2.0).timeout
	choose_random_direction()
	walk_sound.play()
	
func return_home():
	get_route()
	return_points = route_points.duplicate()
	return_points.reverse()
	return_points.append(start_position)
	
	current_return_index = 0
	
	if return_points.size() == 0:
		return
		
	target_position = return_points[current_return_index]
	
	returning_home = true
	moving_to_target = false
	is_active = true
	
	start_sound.play()
	walk_sound.play()

func choose_random_direction():
	var directions = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT
	]
	
	direction = directions.pick_random()

func update_animation(dir: Vector2):
	if dir == Vector2.ZERO:
		sprite.stop()
		return
	
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			sprite.play("walk_right")
		else:
			sprite.play("walk_left")
	else:
		if dir.y > 0:
			sprite.play("walk_down")
		else: 
			sprite.play("walk_up")

func _on_timer_timeout():
	if is_active and !player_nearby:
		choose_random_direction()
		$Timer.wait_time = randf_range(0.8, 2.0)
		$Timer.start()
	
func _on_detection_entered(body):
	if body.name == "Player":
		player = body
		player_nearby = true 
		hit_sound.play()
	
func _on_detection_exited(body):
	if body.name == "Player":
		player = null
		player_nearby = false
		
func get_bot_name() -> String:
	return "Robot"
	
func get_ability() -> String:
	return "none"
	
func execute_task(target):
	if target != null and target.has_method("receive_robot_task"):
		await target.receive_robot_task(self)
		return
	print(get_bot_name() + " cannot perform this task.")
	
func get_route():
	route_points.clear()
	if route_points_parent == null:
		return
	
	for child in route_points_parent.get_children():
		route_points.append(child.global_position)

func move_to_task(target):
	if target == null:
		return
		
	task_target = target
	
	get_route()
	current_route_index = 0
	
	
	if target.has_node("TargetPoint"):
		route_points.append(target.get_node("TargetPoint").global_position)
	else:
		route_points.append(target.global_position)
		
	if route_points.size() == 0:
		return
		
	target_position = route_points[current_route_index]
	
	moving_to_target = true
	returning_home = false
	is_active = true
	start_sound.play()
	walk_sound.play()
