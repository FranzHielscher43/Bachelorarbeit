extends Node2D
class_name CommunicationServer

@export var door_path : NodePath
@onready var door = get_node_or_null(door_path)

@onready var dialogbox = $"../Dialogbox"

var received_signals := {
	"navigation": false,
	"life_support": false,
	"security_channel": false
}

var is_complete := false

@export var ai_core_path : NodePath
@onready var ai_core = get_node_or_null(ai_core_path)

func receive_signal(signal_id: String):
	if is_complete:
		return
		
	if !received_signals.has(signal_id):
		dialogbox.show_dialog("Unknown signal:\n" + signal_id)
		return
		
	received_signals[signal_id] = true
	dialogbox.show_dialog("CommunicationServer.receive_signal()\n\n" + "Message received from:\n" + signal_id + "\n\n" + "Connection saved.")
	
	match signal_id:
		"navigation":
			MissionManager.complete_subtask("communication", "Send navigation signal")
		"life_support":
			MissionManager.complete_subtask("communication", "Send life support signal")
		"security_channel":
			MissionManager.complete_subtask("communication", "Send security channel signal")
		
	await get_tree().create_timer(7.0).timeout
	dialogbox.hide_dialog()
	check_all_signals()
	
func check_all_signals():
	for value in received_signals.values():
		if value == false:
			return
		
	is_complete = true
	if ai_core != null and ai_core.has_method("activate_communication"):
		ai_core.activate_communication()
		
	dialogbox.show_dialog("All signals connected.\n" + "Communication server opening exit door.")
	MissionManager.complete_subtask("communication", "Activate communication system")
	
	if door != null:
		door.open_door()
		
	await get_tree().create_timer(7.0).timeout
	dialogbox.hide_dialog()
