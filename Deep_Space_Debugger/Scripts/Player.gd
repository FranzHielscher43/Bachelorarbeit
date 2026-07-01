extends CharacterBody2D

@export var speed = 150
@onready var footstep = $AudioStreamPlayer2D

var was_moving := false
var last_direction := Vector2.DOWN
var stun := false

func _physics_process(_delta):

	var direction = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)
	
	if stun:
		velocity = Vector2.ZERO
		move_and_slide()
		update_animation(Vector2.ZERO)
		footstep.stream_paused = true
		was_moving = false
		return
	
	if direction != Vector2.ZERO:
		last_direction = direction

	velocity = direction * speed
	move_and_slide()

	update_animation(direction)

	var is_moving = direction != Vector2.ZERO

	if is_moving and !was_moving:
		footstep.stream_paused = false
		if !footstep.playing:
			footstep.pitch_scale = randf_range(1.3, 1.6)
			footstep.play()
			footstep.seek(randf_range(0.0, footstep.stream.get_length()))
	elif !is_moving and was_moving:
		footstep.stream_paused = true
	was_moving = is_moving


func update_animation(direction):

	var sprite = $AnimatedSprite2D

	if direction == Vector2.ZERO:
		sprite.stop()
		return

	if direction.x > 0:
		sprite.play("walk_side")
		sprite.flip_h = false

	elif direction.x < 0:
		sprite.play("walk_side")
		sprite.flip_h = true

	elif direction.y > 0:
		sprite.play("walk_down")
		sprite.flip_h = false

	elif direction.y < 0:
		sprite.play("walk_up")
		sprite.flip_h = false
