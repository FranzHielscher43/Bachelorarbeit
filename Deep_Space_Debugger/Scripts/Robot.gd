extends CharacterBody2D

@export var speed := 60

var direction := Vector2.ZERO
var player_nearby := false
var player = null

@onready var start_sound = $"StartSound"
@onready var walk_sound = $WalkingSound
@onready var hit_sound = $HitSound

func _ready():
	start_sound.play()
	await get_tree().create_timer(2.0).timeout
	choose_random_direction()
	walk_sound.play()
	$Timer.timeout.connect(_on_timer_timeout)
	$PlayerDetection.body_entered.connect(_on_detection_entered)
	$PlayerDetection.body_exited.connect(_on_detection_exited)

func _physics_process(delta):
	if player_nearby and player != null:
		hit_sound.play()
		direction = (global_position - player.global_position).normalized()
	
	velocity = direction * speed
	move_and_slide()
	
	if is_on_wall():
		choose_random_direction()

func choose_random_direction():
	var directions = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT,
		Vector2.ZERO
	]
	
	direction = directions.pick_random()

func _on_timer_timeout():
	choose_random_direction()
	
func _on_detection_entered(body):
	if body.name == "Player":
		player = body
		player_nearby = true 
	
func _on_detection_exited(body):
	if body.name == "Player":
		player = null
		player_nearby = false
