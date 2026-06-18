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

func get_bot_name() -> String:
	return "TransportBot"
	
func get_ability() -> String:
	return "transport"
	
func execute_task(target):
	if target != null and target.has_method("receive_robot_task"):
		target.receive_robot_task(self)
		await get_tree().create_timer(2.5).timeout
		return_home()
		return
	
	if target == object:
		pick_up_object()
		return
		
	if target == drop_zone and carrying_object:
		drop_object()
		await get_tree().create_timer(2.5).timeout
		return_home()
		return
	
	fail_task()

func pick_up_object():
	if object == null or drop_zone == null:
		return
	carrying_object = true
	
	object.reparent(target_point)
	object.position = Vector2.ZERO
	object.visible = true
	
	if object.has_node("CollisionShape2D"):
		object.get_node("CollisionShape2D").disabled = true
	
	if object.has_method("set_carried_by_bot"):
		object.set_carried_by_bot(self)
	transport_sound.play()
	move_to_task(drop_zone)
	
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
	
	transport_sound.play()
	await get_tree().create_timer(3.0).timeout
	return_home()

func fail_task():

	dialogbox.show_dialog(
		"TransportBot.transport() executed.\n" +
		"The relay cannot be transported.\n" +
		"This bot does not have a repair() method."
	)
	await get_tree().create_timer(5.0).timeout
	dialogbox.hide_dialog()
	return_home()
