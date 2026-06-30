extends Area2D
class_name CommunicationServer

@export var door_path : NodePath
@onready var door = get_node_or_null(door_path)

@onready var dialogbox = $"../Dialogbox"

var received_signals := {
	"navigation": false,
	"life_support": false,
	"security_channel": false
}

@export var expected_order := ["navigation", "life_support", "security_channel"]
var current_signal := 0
var is_complete := false

@export var ai_core_path : NodePath
@onready var ai_core = get_node_or_null(ai_core_path)

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func receive_signal(signal_id: String) -> bool:
	if is_complete:
		return true
		
	if !received_signals.has(signal_id):
		dialogbox.show_dialog("Unknown signal:\n" + signal_id)
		return false
		
	if current_signal >= expected_order.size():
		return false
		
	if signal_id != expected_order[current_signal]:
		dialogbox.show_dialog("Server protocol error.\n\n" + "Expected: " + expected_order[current_signal] + "\n" + "Received: " + signal_id)
		return false
		
	received_signals[signal_id] = true
	current_signal += 1
	dialogbox.show_dialog("StationServer.receive_signal()\n\n" + "Message received from:\n" + signal_id + "\n\n" + "Connection saved.")
	
	match signal_id:
		"navigation":
			MissionManager.complete_subtask("communication", "Send navigation signal")
		"life_support":
			MissionManager.complete_subtask("communication", "Send life support signal")
		"security_channel":
			MissionManager.complete_subtask("communication", "Send security channel signal")
		
	check_all_signals()

	await get_tree().create_timer(5.0).timeout
	dialogbox.hide_dialog()
	return true
	
func check_all_signals():
	for value in received_signals.values():
		if value == false:
			return
		
	is_complete = true
	if ai_core != null and ai_core.has_method("activate_communication"):
		ai_core.activate_communication()
		
	dialogbox.show_dialog("All signals connected.\n" + "Station server ready and opening biosphere.", true, "STATION SERVER")
	MissionManager.complete_subtask("communication", "Activate communication system")
	
	if door != null:
		door.open_door()
		
	await get_tree().create_timer(7.0).timeout
	dialogbox.hide_dialog()
	
func _on_body_entered(body):
	if body.name == "Player":
		dialogbox.show_dialog("The station server routes messages\nbetween connected systems.\n\nObjects exchange information by\nsending method calls instead of\ncommunicating directly.\n\nRestore all communication channels\nto reconnect the network.", true, "Station Server")
	
func _on_body_exited(body):
	if body.name == "Player":
		dialogbox.hide_dialog()
