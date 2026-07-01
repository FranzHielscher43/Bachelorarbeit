extends Robot
class_name TransportBot

@onready var dialogbox = $"../Dialogbox"
@export var object_path : NodePath
@export var drop_zone_path : NodePath

@onready var object = get_node_or_null(object_path)
@onready var drop_zone = get_node_or_null(drop_zone_path)
var carrying_object := false

@onready  var transport_sound = $TransportSound

@onready var target_point = $TargetPoint

@export var drop_route_points_parent : Node2D
@export var return_route_points_parent : Node2D
@export var door_path : NodePath
@onready var door = get_node_or_null(door_path)

@export var ai_core_path : NodePath
@onready var ai_core = get_node_or_null(ai_core_path)

func get_bot_name() -> String:
	return "TransportBot"
	
func get_ability() -> String:
	return "transport"
	
func execute_task(target):
	print("TRANSPORT EXECUTE TASK: ", target)

	print("object: ", object)
	print("drop_zone: ", drop_zone)
	print("carrying: ", carrying_object)
	if target == object:
		pick_up_object()
		return
		
	if target == drop_zone and carrying_object:
		drop_object()
		return
		
	if target != null and target.has_method("receive_robot_task"):
		await super.execute_task(target)
		return
	
	fail_task()

func pick_up_object():
	if object == null or drop_zone == null:
		return
	carrying_object = true
	handles_own_return = true
	
	object.reparent(target_point)
	object.position = Vector2.ZERO
	object.visible = true
	
	if object.has_node("CollisionShape2D"):
		object.get_node("CollisionShape2D").disabled = true
	
	if object.has_method("set_carried_by_bot"):
		object.set_carried_by_bot(self)
	transport_sound.play()
	move_to_drop_zone()
	
func drop_object():
	carrying_object = false
	var place_position = drop_zone.global_position

	if drop_zone.has_node("SnapPoint"):
		place_position = drop_zone.get_node("SnapPoint").global_position
		
	var level = get_tree().current_scene
	object.reparent(level)
	object.global_position = place_position
	
	if object.has_method("set_placed_by_bot"):
		object.set_placed_by_bot(place_position)
	if drop_zone.has_method("_on_area_entered"):
		drop_zone._on_area_entered(object)
		
	var terminal = get_tree().get_first_node_in_group("Terminal")
	
	if terminal != null:
		terminal.transport_job_done = true
		terminal.update_robot_button_locks()
	
	transport_sound.play()
	if door != null and door.has_method("open_door"):
		door.open_door()
		MissionManager.complete_subtask("transport", "Wait for the transport robot")

	if ai_core != null:
		ai_core.transport_done = true
		await ai_core.check_core_status()

	await get_tree().create_timer(3.0).timeout
	return_home_from_drop_zone()

func fail_task():

	dialogbox.show_dialog(
		"TransportBot.transport() executed.\n" +
		"The relay cannot be transported.\n" +
		"This bot does not have a repair() method."
	)
	await get_tree().create_timer(5.0).timeout
	dialogbox.hide_dialog()
	return_home()
	
func move_to_drop_zone():
	if drop_zone == null:
		return
		
	task_target = drop_zone
	
	route_points.clear()
	current_route_index = 0
	
	if drop_route_points_parent != null:
		for child in drop_route_points_parent.get_children():
			route_points.append(child.global_position)
	
	if drop_zone.has_node("TargetPoint"):
		route_points.append(drop_zone.get_node("TargetPoint").global_position)
	else:
		route_points.append(drop_zone.global_position)
	
	if route_points.size() == 0:
		return
	
	target_position = route_points[current_route_index]
	moving_to_target = true
	returning_home = false
	is_active = true
	
	start_sound.play()
	if !walk_sound.playing:
		walk_sound.play()
		
func return_home_from_drop_zone():
	handles_own_return = false
	return_points.clear()

	if return_route_points_parent != null:
		for child in return_route_points_parent.get_children():
			return_points.append(child.global_position)

	return_points.append(start_position)

	current_return_index = 0

	if return_points.size() == 0:
		return

	target_position = return_points[current_return_index]

	returning_home = true
	moving_to_target = false
	is_active = true

	start_sound.play()
	if !walk_sound.playing:
		walk_sound.play()
