extends Area2D

@export_file("*.tscn") var next_level_path := ""
@export var fade_duration := 1.0

@export var player_point_path : NodePath
@onready var player_point = get_node_or_null(player_point_path)
@export var player_z_index := -1
var player_collision = null

@export var inner_sprite_path : NodePath
@onready var inner_sprite = get_node_or_null(inner_sprite_path)
@export var outer_sprite_path : NodePath
@onready var outer_sprite = get_node_or_null(outer_sprite_path)
@export var outer_sprite_z_index := 2
@export var player_target_offset := Vector2(0, 8)

@export var use_elevator := false
@export var elevator_sprite_path : NodePath
@onready var elevator_sprite = get_node_or_null(elevator_sprite_path)
@export var elevator_move_offset := Vector2(0, 8)
@export var elevator_move_duration := 2.0

@onready var fade_rect = $CanvasLayer/FadeRect
var is_transitioning := false
var fade_started := false

@export var completes_mission := ""
@export var completes_subtask := ""

@onready var elevator_sound = $ElevatorSound

func _ready():
	if use_elevator:
		if inner_sprite != null:
			inner_sprite.visible = false
		if outer_sprite != null:
			outer_sprite.visible = false
		if elevator_sprite != null:
			elevator_sprite.visible = true
	else:
		if inner_sprite != null:
			inner_sprite.visible = true
		if outer_sprite != null:
			outer_sprite.visible = true
		if elevator_sprite != null:
			elevator_sprite.visible = false
		
	body_entered.connect(_on_body_entered)
	fade_rect.modulate.a = 0.0

func _on_body_entered(body):
	if is_transitioning:
		return
		
	if body.name != "Player":
		return
	
	if next_level_path == "":
		return
	
	if completes_mission != "" and completes_subtask != "":
		MissionManager.complete_subtask(completes_mission, completes_subtask)
	await get_tree().create_timer(0.5).timeout
	
	is_transitioning = true
	
	body.stun = true
	body.velocity = Vector2.ZERO
	
	if body.has_node("CollisionShape2D"):
		player_collision = body.get_node("CollisionShape2D")
		player_collision.disabled = true

	if player_point != null:
		body.global_position = player_point.global_position
		body.z_index = player_z_index
		
	if outer_sprite != null:
		outer_sprite.z_index = outer_sprite_z_index
				
	var tween = create_tween()
	
	var final_player_position := Vector2.ZERO
	
	if use_elevator and elevator_sprite != null:
		final_player_position = body.global_position + elevator_move_offset
		var elevator_target_position = elevator_sprite.global_position + elevator_move_offset
		
		tween.tween_method(func(pos): body.global_position = pos, body.global_position, final_player_position, elevator_move_duration)
		elevator_sound.play()
		tween.parallel().tween_property(elevator_sprite, "global_position", elevator_target_position, elevator_move_duration)
		await get_tree().create_timer(elevator_move_duration * 0.5).timeout
		fade_started = true
		fade_out()
	else:
		final_player_position = body.global_position + player_target_offset
		tween.tween_property(body, "global_position", final_player_position, 2.0)
		
		
	await tween.finished
	body.velocity = Vector2.ZERO
	body.global_position = final_player_position 
	
	if !fade_started:
		await fade_out()
	else:
		while fade_rect.modulate.a < 0.99:
			await get_tree().process_frame
	
	if player_collision != null:
		player_collision.disabled = false
	
	get_tree().change_scene_to_file(next_level_path)

func fade_out():
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished
