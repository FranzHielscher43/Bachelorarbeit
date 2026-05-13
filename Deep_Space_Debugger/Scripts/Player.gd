extends CharacterBody2D

const SPEED = 200.0

func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	
	# Eingaben für alle Richtungen
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	velocity = direction * SPEED
	
	move_and_slide()
