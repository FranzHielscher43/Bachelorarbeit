extends CanvasLayer

@onready var terminal_root = $Control
@onready var in_game_menu = $"../InGameMenu"

@onready var overview_button = $Control/OuterBackgroundPanel/InnerBackgroundPanel/MenuPanel/VBoxContainer/Overview
@onready var energy_button = $Control/OuterBackgroundPanel/InnerBackgroundPanel/MenuPanel/VBoxContainer/Energy
@onready var security_button = $Control/OuterBackgroundPanel/InnerBackgroundPanel/MenuPanel/VBoxContainer/Security
@onready var logs_button = $Control/OuterBackgroundPanel/InnerBackgroundPanel/MenuPanel/VBoxContainer/Logs
@onready var quit_button = $Control/OuterBackgroundPanel/InnerBackgroundPanel/MenuPanel/VBoxContainer/Quit

@onready var method_button = $Control/OuterBackgroundPanel/InnerBackgroundPanel/ContentPanel/DataPanel/MethodButton
var current_method := ""
var complete_methods := {}

@onready var mission_ui = $"../MissionStatus"

@export var terminal_level := 1

# Level 01
@export var power_system_path : NodePath
@onready var power_system = get_node_or_null(power_system_path)

#Level 02
@export var security_door_path : NodePath
@onready var security_door = get_node_or_null(security_door_path)
var access_module_inserted := false

#Level 03
@export var repair_bot_path : NodePath
@export var security_bot_path : NodePath
@export var transport_bot_path : NodePath
@export var communication_relay_path : NodePath
@onready var repair_bot = get_node_or_null(repair_bot_path)
@onready var security_bot = get_node_or_null(security_bot_path)
@onready var transport_bot = get_node_or_null(transport_bot_path)
@onready var communication_relay = get_node_or_null(communication_relay_path)
var selected_bot = null
var selected_bot_method := ""
@onready var repair_bot_button = $Control/OuterBackgroundPanel/InnerBackgroundPanel/ContentPanel/DataPanel/RepairBotButton
@onready var security_bot_button = $Control/OuterBackgroundPanel/InnerBackgroundPanel/ContentPanel/DataPanel/SecurityBotButton
@onready var transport_bot_button = $Control/OuterBackgroundPanel/InnerBackgroundPanel/ContentPanel/DataPanel/TransportBotButton
var transport_job_done := false
@export var elevator_door_path : NodePath
@onready var elevator_door = get_node_or_null(elevator_door_path)

#Level 04
@export var ai_core_path : NodePath
@onready var ai_core = get_node_or_null(ai_core_path)

@onready var title_label = $Control/OuterBackgroundPanel/InnerBackgroundPanel/TitleLabel
@onready var info_label = $Control/OuterBackgroundPanel/InnerBackgroundPanel/ContentPanel/InformationPanel/Label
@onready var data_label = $Control/OuterBackgroundPanel/InnerBackgroundPanel/ContentPanel/DataPanel/Label
@onready var ping_label = $Control/OuterBackgroundPanel/InnerBackgroundPanel/ConnectionPanel/PingInformation
@onready var ping_timer = $Control/OuterBackgroundPanel/InnerBackgroundPanel/ConnectionPanel/PingTimer

@onready var signal_bars = [
	$Control/OuterBackgroundPanel/InnerBackgroundPanel/ConnectionPanel/SignalPanel/Bar1,
	$Control/OuterBackgroundPanel/InnerBackgroundPanel/ConnectionPanel/SignalPanel/Bar2,
	$Control/OuterBackgroundPanel/InnerBackgroundPanel/ConnectionPanel/SignalPanel/Bar3,
	$Control/OuterBackgroundPanel/InnerBackgroundPanel/ConnectionPanel/SignalPanel/Bar4,
	$Control/OuterBackgroundPanel/InnerBackgroundPanel/ConnectionPanel/SignalPanel/Bar5
]

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound
@onready var success_sound = $SuccessSound

var ping := 25
var target_ping := 25
var is_open := false
@onready var player = $"../Player"

func _ready():
	$Control.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	overview_button.pressed.connect(_on_overview_pressed)
	energy_button.pressed.connect(_on_energy_pressed)
	security_button.pressed.connect(_on_security_pressed)
	logs_button.pressed.connect(_on_logs_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	method_button.pressed.connect(_on_method_pressed)
	method_button.visible = false
	
	overview_button.focus_entered.connect(_on_button_hover)
	energy_button.focus_entered.connect(_on_button_hover)
	security_button.focus_entered.connect(_on_button_hover)
	logs_button.focus_entered.connect(_on_button_hover)
	quit_button.focus_entered.connect(_on_button_hover)

	method_button.focus_entered.connect(_on_button_hover)
	
	repair_bot_button.pressed.connect(_on_repair_bot_selected)
	security_bot_button.pressed.connect(_on_security_bot_selected)
	transport_bot_button.pressed.connect(_on_transport_bot_selected)
	repair_bot_button.visible = false
	security_bot_button.visible = false
	transport_bot_button.visible = false
	
	repair_bot_button.focus_entered.connect(_on_button_hover)
	security_bot_button.focus_entered.connect(_on_button_hover)
	transport_bot_button.focus_entered.connect(_on_button_hover)
	
	randomize()
	target_ping = randi_range(15, 45)
	ping_timer.timeout.connect(_update_ping)
	_update_ping()
	
func _input(event):
	if !is_open:
		return
	
	if event.is_action_pressed("ui_cancel"):
		close_terminal()
		in_game_menu.toggle_pause()
		get_viewport().set_input_as_handled()
		
func _on_overview_pressed():
	click_sound.play()
	await click_sound.finished
	show_overview()

func _on_energy_pressed():
	click_sound.play()
	await click_sound.finished
	show_energy()
	
func _on_security_pressed():
	click_sound.play()
	await click_sound.finished
	show_security()

func _on_logs_pressed():
	click_sound.play()
	await click_sound.finished
	show_logs()
	
func _on_quit_pressed():
	click_sound.play()
	await click_sound.finished
	close_terminal()
	
func _on_repair_bot_selected():
	click_sound.play()
	selected_bot = repair_bot
	selected_bot_method = "send_repair_bot"
	update_button_highlight()
	current_method = selected_bot_method
	
func _on_security_bot_selected():
	click_sound.play()
	selected_bot = security_bot
	selected_bot_method = "send_security_bot"
	update_button_highlight()
	current_method = selected_bot_method
	
func _on_transport_bot_selected():
	click_sound.play()
	selected_bot = transport_bot
	selected_bot_method = "send_transport_bot"
	update_button_highlight()
	current_method = selected_bot_method
	
func get_selected_bot_name() -> String:
	if selected_bot == null:
		return ""
	return selected_bot.get_bot_name()

func _on_method_pressed():
	click_sound.play()
	await  click_sound.finished
	
	match current_method:
		"request_access":
			MissionManager.complete_subtask("security_access", "Request clearance")
			execute_request_access()
		"send_repair_bot":
			MissionManager.complete_subtask("robotics", "Select & send repair robot")
			execute_send_repair_bot()
		"send_security_bot":
			MissionManager.complete_subtask("robotics", "Select & send security robot")
			execute_send_security_bot()
		"send_transport_bot":
			MissionManager.complete_subtask("robotics", "Select & send transport robot")
			execute_send_transport_bot()
		"send_all_robots":
			execute_send_all_robots()

	close_terminal()
	
func insert_access_module():
	access_module_inserted = true
	if is_open:
		show_security()
	
func execute_request_access():
	if security_door == null:
		return
		
	await get_tree().create_timer(1.0).timeout
	security_door.grant_access()
	success_sound.play()
	
	complete_methods["request_access"] = true
	method_button.disabled = true
	method_button.text = "ACCESS GRANTED"
	current_method = ""
	
func execute_send_repair_bot():
	if repair_bot == null:
		return
	
	if terminal_level == 4 and is_ai_core_available():
		repair_bot.move_to_task(ai_core)
	elif communication_relay != null:
		repair_bot.move_to_task(communication_relay)
		complete_methods["send_repair_bot"] = true
		
	current_method = ""
		
func execute_send_security_bot():
	if security_bot == null:
		return
	
	if terminal_level == 4 and is_ai_core_available():
		security_bot.move_to_task(ai_core)
	elif transport_job_done and elevator_door != null:
		security_bot.move_to_task(elevator_door)
	elif communication_relay != null:
		security_bot.move_to_task(communication_relay)
		
	current_method = ""
	
func execute_send_transport_bot():
	if transport_bot == null:
		return
	
	if terminal_level == 4 and is_ai_core_available():
		transport_bot.move_to_task(ai_core)
	elif communication_relay != null and communication_relay.has_method("is_repaired") and communication_relay.is_repaired():
		transport_bot.move_to_task(transport_bot.object)
	elif communication_relay != null:
		transport_bot.move_to_task(communication_relay)
		
	current_method = ""
	
func execute_send_all_robots():
	if terminal_level != 4:
		return
	
	if !is_ai_core_available():
		return
		
	if repair_bot == null or security_bot == null or transport_bot == null:
		return
		
	current_method = ""
	method_button.disabled = true
	method_button.text = "ROBOTS DEPLOYED"
	
	repair_bot.move_to_task(ai_core)
	await get_tree().create_timer(5.0).timeout
	security_bot.move_to_task(ai_core)
	await get_tree().create_timer(5.0).timeout
	transport_bot.move_to_task(ai_core)

func show_title():
	title_label.clear()
	title_label.append_text("""[font_size=40]TERMINAL_01[/font_size]\n[font_size=24]STATION: ECLIPSE-9[/font_size]""")
	
func show_overview():
	info_label.clear()
	data_label.clear()
	
	if terminal_level == 4:
		info_label.append_text("""[font_size=24]COMMUNICATION CENTER[/font_size]\nThe station network has been restored.\nAll connected systems can now exchange messages.\nThe AI core is ready to receive a unified command.\nLearning goal:\nObject communication and polymorphism.""")
		data_label.append_text(
			"> NETWORK.......[color=#15ba12]ONLINE[/color]\n\n" +
			"> MESSAGE CALL..[color=#f7c948]receive_signal()[/color]\n\n" +
			"> AI CORE.......[color=#15ba12]" + ("ONLINE" if ai_core != null and ai_core.core_online else "READY") + "[/color]\n\n" +
			"> NEXT TASK.....[color=#f7c948]Send all robots[/color]"
		)
		method_button.visible = false
		repair_bot_button.visible = false
		security_bot_button.visible = false
		transport_bot_button.visible = false
		return
	
	if terminal_level == 3:
		if communication_relay != null and communication_relay.is_repaired():
			info_label.append_text("""[font_size=24]ROBOTICS CENTER[/font_size]\n\nThe communication relay has been repaired successfully.\n\nThe RepairRobot executed its specialized repair() method.\n\nLearning goal:\nSUBCLASSES inherit shared behavior and specialize it with their own methods.""")
			data_label.append_text(
				"> AREA..........[color=#15ba12]ROBOTICS ONLINE[/color]\n\n" +
				"> BASE CLASS....[color=#15ba12]Robot[/color]\n\n" +
				"> EXECUTED......[color=#15ba12]RepairBot.repair()[/color]\n\n" +
				"> RELAY.........[color=#15ba12]REPAIRED[/color]\n\n" +
				"> STATUS........[color=#15ba12]COMMUNICATION READY[/color]"
			)
		else:
			info_label.append_text("""[font_size=24]ROBOTICS CENTER[/font_size]\n\nThe robotics center manages specialized maintenance robots.\n\nAll available units are based on the shared Robot BASE CLASS.\n\nEach SUBCLASS extends this BASE CLASS with its own specialized ability.\n\nLearning goal:\nInheritance and specialization.""")
			data_label.append_text(
				"> AREA..........[color=#f7c948]ROBOTICS[/color]\n\n" +
				"> BASE CLASS....[color=#f7c948]Robot[/color]\n\n" +
				"> SUBCLASSES....[color=#15ba12]Repair / Security / Transport[/color]\n\n" +
				"> TARGET........[color=#f7c948]Repair communication relay[/color]\n\n" +
				"> SELECTED......[color=#15ba12]" + get_selected_bot_name() + "[/color]"
			)
		method_button.visible = false
		return
		
	if terminal_level == 2:
		if complete_methods.has("request_access"):
			info_label.append_text("""[font_size=24]SECURITY OVERVIEW[/font_size]\n\nSecurity clearance has been granted.\n\nThe door state was not changed directly.\nInstead, the terminal called a PUBLIC METHOD on the security system.\n\nLearning goal:\nEncapsulation protects internal states and exposes controlled access through methods.""")
			data_label.append_text("> AREA..........[color=#15ba12]SECURITY[/color]\n\n" +"> ACCESS........[color=#15ba12]GRANTED[/color]\n\n" +"> METHOD........[color=#15ba12]request_access()[/color]\n\n" +"> DOOR STATE....[color=#15ba12]UNLOCKED[/color]\n\n" +"> NEXT SECTOR...[color=#f7c948]ROBOTICS[/color]")
		else:
			info_label.append_text("""[font_size=24]SECURITY OVERVIEW[/font_size]\n\nThis sector is protected by an ENCAPSULATED security door.\n\nDirect access is denied.\n\nA compatible AccessModule is required before clearance can be requested.\n\nLearning goal:\nUse methods to interact with protected object states.""")
			data_label.append_text("> AREA..........[color=#f7c948]SECURITY[/color]\n\n" + "> ACCESS........[color=#ff4d4d]DENIED[/color]\n\n" +"> REQUIRED......[color=#f7c948]AccessModule[/color]\n\n" +"> METHOD........[color=#f7c948]request_access()[/color]\n\n" +"> TASK..........[color=#f7c948]Insert ACCESS MODULE[/color]")
		method_button.visible = false
		return
		
	if terminal_level == 0:
		info_label.append_text("""[font_size=24]SYSTEM OVERVIEW[/font_size]\n\nThis terminal provides basic station information.\n\nUse the terminal menu to switch between available sections.\n\nLearning goal:\nTerminals are interactive objects that provide access to system information.""")
		data_label.append_text("> TERMINAL......[color=#15ba12]ONLINE[/color]\n\n" +"> MODE..........[color=#f7c948]TUTORIAL[/color]\n\n" +"> AVAILABLE.....[color=#15ba12]OVERVIEW / LOGS[/color]\n\n" +"> NEXT TASK.....[color=#f7c948]Check the logs or close the terminal[/color]")
		method_button.visible = false
		repair_bot_button.visible = false
		security_bot_button.visible = false
		transport_bot_button.visible = false
		return

	if is_power_enabled():
		info_label.append_text("""[font_size=24]STATION OVERVIEW[/font_size]\n\nWelcome to the station management system.\n\nPower supply has been restored.\nThe inserted energy core OBJECT was recognized as a valid OBJECT of the EnergyCore CLASS.\n\nLearning progress:\nCLASSES describe blueprints.\nOBJECTS are concrete INSTANCES with their own ATTRIBUTE values.""")
		data_label.append_text("""> STATUS..........[color=#15ba12]ACTIVE[/color]\n\n> SECTOR..........B-03\n\n> POWER...........[color=#15ba12]ONLINE[/color]\n\n> SECURITY........[color=#ff4d4d]INACTIVE[/color]\n\n> COMMUNICATION...[color=#ff4d4d]INACTIVE[/color]\n\n> AI-CORE.........[color=#ff4d4d]INACTIVE[/color]\n\n> TASK............[color=#15ba12]DONE[/color]\n\n> NEXT SECTOR.....[color=#f7c948]SECURITY[/color]""")
	else:
		info_label.append_text("""[font_size=24]STATION OVERVIEW[/font_size]\n\nWelcome to the station management system.\n\nThe station is controlled by several software and hardware systems.\nEach system is represented as an OBJECT with its own properties and functions.\n\nHint:\nNot every OBJECT has the required ATTRIBUTES for the current task.""")
		data_label.append_text("""> STATUS..........[color=#15ba12]ACTIVE[/color]\n\n> SECTOR..........B-03\n\n> ENERGY..........[color=#ff4d4d]UNSTABLE[/color]\n\n> SECURITY........[color=#ff4d4d]INACTIVE[/color]\n\n> COMMUNICATION...[color=#ff4d4d]INACTIVE[/color]\n\n> AI-Core.........[color=#ff4d4d]INACTIVE[/color]\n\n> TASK............[color=#f7c948]FIND ENERGY CORE[/color]""")

	method_button.visible = false
	
func is_power_enabled() -> bool:
	return power_system != null and power_system.power_enabled	

func show_energy():
	info_label.clear()
	data_label.clear()
	
	if terminal_level == 4:
		show_ai_core()
		return
	
	if terminal_level == 3:
		show_robotics()
		return
		
	if terminal_level == 2:
		energy_button.visible = false

	if is_power_enabled():
		info_label.append_text("""[font_size=24]POWER SUPPLY[/font_size]\n\nSTATUS: [color=#15ba12]ONLINE[/color]\n\nThe correct energy core has been inserted.\n\nEvaluation:\nEnergyCore_B is an OBJECT of the EnergyCore CLASS.\nIt contains the required ATTRIBUTE values for the generator.\nThis demonstrates the difference between a CLASS and an OBJECT.""")
		data_label.append_text("""> CLASS...............[color=#15ba12]EnergyCore[/color]\n\n> USED OBJECT.........[color=#15ba12]EnergyCore_B[/color]\n\n> CAPACITY............[color=#15ba12]90[/color]\n\n> STABILITY...........[color=#15ba12]95[/color]\n\n> STATE...............[color=#15ba12]stable[/color]\n\n> STATUS..............[color=#15ba12]POWER ONLINE[/color]""")
	else:
		info_label.append_text("""[font_size=24]POWER SUPPLY[/font_size]\n\nLearning goal: CLASSES and OBJECTS\n\nAll energy cores belong to the EnergyCore CLASS.\nThe CLASS describes the blueprint.\nEach individual energy core is an OBJECT.\nOBJECTS of the same CLASS share the same ATTRIBUTE types, but have different values.\n\nTask:\nFind the correct energy core for the generator.""")
		data_label.append_text("""> REQUIRED CLASS......[color=#f7c948]EnergyCore[/color]\n\n> CAPACITY............[color=#f7c948]90[/color]\n\n> STABILITY...........[color=#f7c948]95[/color]\n\n> STATE...............[color=#f7c948]stable[/color]\n\n> HINT................COMPARE ATTRIBUTES""")
	method_button.visible = false

func show_security():
	info_label.clear()
	data_label.clear()
	
	if terminal_level == 4:
		show_ai_task()
		return
	
	if terminal_level == 3:
		show_robot_task()
		return

	if !access_module_inserted:
		info_label.append_text("""[font_size=24]SECURITY SYSTEM[/font_size]\n\nThe security console requires an AccessModule.\n\nOnly a compatible module can request clearance.\n\nLearning goal:\nENCAPSULATION protects internal system states from direct access.""")
		data_label.append_text("""> SYSTEM...........SECURITY_DOOR\n\n> STATUS...........[color=#ff4d4d]LOCKED[/color]\n\n> ACCESS MODULE....[color=#ff4d4d]NOT INSERTED[/color]\n\n> REQUIRED CLASS...[color=#f7c948]AccessModule[/color]\n\n> CLEARANCE........[color=#f7c948]3[/color]\n\n> ACTIVE...........[color=#f7c948]true[/color]""")
		method_button.visible = false
		return
	if !complete_methods.has("request_access"):
		info_label.append_text("""[font_size=24]SECURITY SYSTEM[/font_size]\n\nCompatible AccessModule detected.\n\nThe security console can now request clearance.\n\nLearning goal:\nMethods provide controlled access to encapsulated states.""")
		data_label.append_text("""> SYSTEM...........SECURITY_DOOR\n\n> STATUS...........[color=#ff4d4d]LOCKED[/color]\n\n> ACCESS MODULE....[color=#15ba12]DETECTED[/color]\n\n> ACCESS...........[color=#ff4d4d]FALSE[/color]\n\n> METHOD...........[color=#f7c948]request_access()[/color]""")
		current_method = "request_access"
		method_button.visible = true
		method_button.disabled = false
		method_button.text = "REQUEST CLEARANCE"
		return
	info_label.append_text("""[font_size=24]SECURITY SYSTEM[/font_size]\n\nAccess has been granted successfully.\n\nThe security system encapsulates the door state.\n\nThe door can only be unlocked through a PUBLIC METHOD.""")
	data_label.append_text("""> SYSTEM........SECURITY_DOOR\n\n> STATUS........[color=#15ba12]UNLOCKED[/color]\n\n> ACCESS........[color=#15ba12]TRUE[/color]\n\n> METHOD........[color=#15ba12]request_access()[/color]\n\n> HINT..........The door can now be opened""")
	method_button.visible = true
	method_button.disabled = true
	method_button.text = "ACCESS GRANTED"

func show_logs():
	info_label.clear()
	data_label.clear()
		
	if terminal_level == 4:
		info_label.append_text("""[font_size=24]COMMUNICATION LOGS[/font_size]\n\nThe latest network events show the communication flow between station systems.""")
		data_label.append_text(
			"> [12:01] [color=#15ba12]SIGNAL NODE A CONNECTED[/color]\n\n" +
			"> [12:02] [color=#15ba12]SIGNAL NODE B CONNECTED[/color]\n\n" +
			"> [12:03] [color=#15ba12]SIGNAL NODE C CONNECTED[/color]\n\n" +
			"> [12:04] [color=#15ba12]COMMUNICATION SERVER ONLINE[/color]\n\n" +
			"> [12:05] [color=#f7c948]AI CORE READY FOR execute_task()[/color]"
		)
		method_button.visible = false
		repair_bot_button.visible = false
		security_bot_button.visible = false
		transport_bot_button.visible = false
		return
	
	if terminal_level == 3:
		info_label.append_text("""[font_size=24]ROBOTICS LOGS[/font_size]\n\nThe robotics logs document the registered robot subclasses and their task execution.""")
		if communication_relay != null and communication_relay.is_repaired():
			data_label.append_text("""> [11:02] [color=#15ba12]BASE CLASS Robot LOADED[/color]\n\n> [11:03] [color=#f7c948]SUBCLASS RepairBot REGISTERED[/color]\n\n> [11:03] [color=#f7c948]SUBCLASS SecurityBot REGISTERED[/color]\n\n> [11:04] [color=#f7c948]SUBCLASS TransportBot REGISTERED[/color]\n\n> [11:05] [color=#ff4d4d]CommunicationRelay DAMAGED[/color]\n\n> [11:06] [color=#f7c948]REQUIRED METHOD: repair()[/color]\n\n> [11:07] [color=#15ba12]RepairBot DEPLOYED[/color]\n\n> [11:08] [color=#15ba12]Communication relay REPAIRED[/color]""")
		else:
			data_label.append_text("""> [11:02] [color=#15ba12]BASE CLASS Robot LOADED[/color]\n\n> [11:03] [color=#f7c948]SUBCLASS RepairBot REGISTERED[/color]\n\n> [11:03] [color=#f7c948]SUBCLASS SecurityBot REGISTERED[/color]\n\n> [11:04] [color=#f7c948]SUBCLASS TransportBot REGISTERED[/color]\n\n> [11:05] [color=#ff4d4d]Communication relay DAMAGED[/color]\n\n> [11:06] [color=#f7c948]REQUIRED METHOD: repair()[/color]""")
		method_button.visible = false
		repair_bot_button.visible = false
		security_bot_button.visible = false
		transport_bot_button.visible = false
		return
		
	if terminal_level == 2:
		info_label.append_text("""[font_size=24]SECURITY LOGS[/font_size]\n\nThe security logs document access attempts and method calls used to interact with encapsulated objects.""")
		if complete_methods.has("request_access"):
			data_label.append_text("> [10:51] [color=#ff4d4d]DIRECT ACCESS DENIED[/color]\n\n" +"> [10:52] [color=#f7c948]AccessModule REQUIRED[/color]\n\n" +"> [10:53] [color=#15ba12]COMPATIBLE MODULE DETECTED[/color]\n\n" +"> [10:54] [color=#f7c948]METHOD CALLED: request_access()[/color]\n\n" +"> [10:55] [color=#15ba12]ACCESS GRANTED[/color]\n\n" +"> [10:56] [color=#15ba12]SECURITY DOOR UNLOCKED[/color]")
		else:
			data_label.append_text("> [10:51] [color=#ff4d4d]DIRECT ACCESS DENIED[/color]\n\n" +"> [10:52] [color=#f7c948]AccessModule REQUIRED[/color]\n\n" +"> [10:53] [color=#ff4d4d]ACCESS STATE PROTECTED[/color]\n\n" +"> [10:54] [color=#f7c948]WAITING FOR request_access()[/color]")
		method_button.visible = false
		repair_bot_button.visible = false
		security_bot_button.visible = false
		transport_bot_button.visible = false
		return
		
	if terminal_level == 0:
		info_label.append_text("""[font_size=24]TUTORIAL LOGS[/font_size]\n\nThe latest boot events were recorded successfully.\n\nUse this terminal to confirm that the station interface is operational.""")
		data_label.append_text("> [09:00] [color=#15ba12]CRYOSTASIS TERMINATED[/color]\n\n" +"> [09:01] [color=#15ba12]PLAYER INPUT MODULE ONLINE[/color]\n\n" +"> [09:02] [color=#15ba12]MISSION STATUS CONNECTED[/color]\n\n" +"> [09:03] [color=#f7c948]TRAINING OBJECT AVAILABLE[/color]\n\n" +"> [09:04] [color=#f7c948]AWAITING ENGINEER INPUT[/color]")
		method_button.visible = false
		repair_bot_button.visible = false
		security_bot_button.visible = false
		transport_bot_button.visible = false
		return

	if is_power_enabled():
		info_label.append_text("""[font_size=24]SYSTEM LOGS[/font_size]\n\nThe latest maintenance events were completed successfully.\n\nThe generator was reactivated by a compatible object.""")
		data_label.append_text("""> [10:41] [color=#15ba12]SYSTEM START[/color]\n\n> [10:45] [color=#f7c948]ENERGY CORE CLASS DETECTED[/color]\n\n> [10:46] [color=#15ba12]OBJECT ENERGYCORE_B ANALYZED[/color]\n\n> [10:46] [color=#15ba12]ATTRIBUTES VALIDATED[/color]\n\n> [10:47] [color=#15ba12]OBJECT ACCEPTED[/color]\n\n> [10:48] [color=#15ba12]GENERATOR ACTIVATED[/color]\n\n> [10:48] [color=#15ba12]POWER SUPPLY ONLINE[/color]\n\n> [10:49] [color=#15ba12]SECURITY CENTER UNLOCKED[/color]""")
	else:
		info_label.append_text("""[font_size=24]SYSTEMPROTOKOLLE[/font_size]\n\nThe logs document important events and state changes inside the station.""")
		data_label.append_text("""> [10:41] [color=#15ba12]SYSTEM START[/color]\n\n> [10:42] [color=#ff4d4d]POWER ERROR DETECTED[/color]\n\n> [10:42] [color=#ff4d4d]GENERATOR DEACTIVATED[/color]\n\n> [10:43] [color=#ff4d4d]SECURITY CENTER LOCKED[/color]\n\n> [10:44] [color=#15ba12]MAINTENANCE MODE ACTIVE[/color]\n\n> [10:45] [color=#f7c948]SEARCHING FOR COMPATIBLE ENERGY CORE[/color]""")
	method_button.visible = false
	
func show_robotics():
	info_label.clear()
	data_label.clear()
	repair_bot_button.visible = false
	security_bot_button.visible = false
	transport_bot_button.visible = false

	if communication_relay != null and communication_relay.is_repaired():
		info_label.append_text("""[font_size=24]ROBOT CONTROL[/font_size]\n\nThe communication relay is back online.\n\nNew transport task is available.\n\nSend a suitable robot to move the energy core to the drop zone.""")

		data_label.append_text(
			"> TASK..........[color=#f7c948]Transport energy core[/color]\n\n" +
			"> REQUIRED......[color=#f7c948]transport()[/color]\n\n" +
			"> SELECTED......[color=#15ba12]" + get_selected_bot_name() + "[/color]\n\n" +
			"> TARGET........[color=#f7c948]Drop zone[/color]"
		)

		method_button.visible = true
		method_button.disabled = selected_bot == null
		method_button.text = "SEND SELECTED ROBOT"
		return

	info_label.append_text("""[font_size=24]ROBOT SYSTEM[/font_size]\n\nMultiple robot types are available.\n\nAll robots inherit from the base CLASS Robot, but each SUBCLASS provides its own specialized ability.""")
	data_label.append_text("""> BASE CLASS....[color=#f7c948]Robot[/color]\n\n> RepairBot......[color=#15ba12]ability = repair[/color]\n\n> SecurityBot....[color=#f7c948]ability = security[/color]\n\n> TransportBot...[color=#f7c948]ability = transport[/color]\n\n> TASK...........[color=#f7c948]Select a suitable robot[/color]""")

	method_button.visible = true
	method_button.disabled = selected_bot == null
	method_button.text = "SEND SELECTED ROBOT"

func show_robot_task():
	info_label.clear()
	data_label.clear()
	
	if communication_relay != null and communication_relay.is_repaired():
		info_label.append_text("""[font_size=24]TRANSPORT TASK[/font_size]\n\nCommunication relay has been repaired.\n\nNow an energy core must be transported to the dropzone.\n\nSelect a robot with the matching transport() ability.""")
		data_label.append_text(
			"> TARGET.........[color=#f7c948]Dropzone[/color]\n\n" +
			"> REQUIRED.......[color=#f7c948]transport()[/color]\n\n" +
			"> RepairBot......[color=#ff4d4d]repair()[/color]\n\n" +
			"> SecurityBot....[color=#ff4d4d]scan()[/color]\n\n" +
			"> TransportBot...[color=#15ba12]transport()[/color]\n\n" +
			"> SELECTED.......[color=#15ba12]" + get_selected_bot_name() + "[/color]"
		)
		repair_bot_button.visible = true
		security_bot_button.visible = true
		transport_bot_button.visible = true
		repair_bot_button.text = "SELECT REPAIRBOT"
		security_bot_button.text = "SELECT SECURITYBOT"
		transport_bot_button.text = "SELECT TRANSPORTBOT"
		method_button.visible = false
		update_button_highlight()
		return

	info_label.append_text("""[font_size=24]REPAIR TASK[/font_size]\n\nCommunication relay is damaged.\n\nSelect a robot with the matching repair() ability first, then send it to the target.""")
	data_label.append_text(
		"> TARGET.........[color=#f7c948]Communication relay[/color]\n\n" +
		"> REQUIRED.......[color=#f7c948]repair()[/color]\n\n" +
		"> SELECTED.......[color=#15ba12]" + get_selected_bot_name() + "[/color]\n\n"
	)

	repair_bot_button.visible = true
	security_bot_button.visible = true
	transport_bot_button.visible = true
	repair_bot_button.text = "SELECT REPAIRBOT"
	security_bot_button.text = "SELECT SECURITYBOT"
	transport_bot_button.text = "SELECT TRANSPORTBOT"
	method_button.visible = false
	update_button_highlight()
	
func show_ai_core():
	info_label.clear()
	data_label.clear()
	repair_bot_button.visible = false
	security_bot_button.visible = false
	transport_bot_button.visible = false
	
	if !is_ai_core_available():
		info_label.append_text("""[font_size=24]KI-KERN[/font_size]

Der KI-Kern ist noch nicht erreichbar.

Stelle zuerst das Kommunikationsnetzwerk wieder her.""")

		data_label.append_text("> STATUS........[color=#ff4d4d]OFFLINE[/color]")
		method_button.visible = false
		return
	info_label.append_text("""[font_size=24]KI-KERN[/font_size]

Das Kommunikationsnetzwerk ist online.

Alle Roboter können nun mit demselben Methodenaufruf entsendet werden.

Lernziel:

Polymorphie - gleicher Aufruf, unterschiedliches Verhalten.""")

	data_label.append_text(
		"> AUFRUF........[color=#f7c948]execute_task()[/color]\n\n" +
		"> RepairBot.....[color=#15ba12]" + str(ai_core.repair_done) + "[/color]\n\n" +
		"> SecurityBot...[color=#15ba12]" + str(ai_core.security_done) + "[/color]\n\n" +
		"> TransportBot..[color=#15ba12]" + str(ai_core.transport_done) + "[/color]\n\n" +
		"> KI-KERN.......[color=#f7c948]" + ("ONLINE" if ai_core.core_online else "WARTET") + "[/color]"
	)
	method_button.visible = false
	
func show_ai_task():
	info_label.clear()
	data_label.clear()
	
	if !is_ai_core_available():
		info_label.append_text("""[font_size=24]EINSATZSTEUERUNG[/font_size]

Kommunikationsnetzwerk offline.

Die Roboter können den KI-Kern noch nicht erreichen.""")

		data_label.append_text("> AUFGABE.......[color=#ff4d4d]Kommunikation herstellen[/color]")
		method_button.visible = false
		return
	info_label.append_text("""[font_size=24]EINSATZSTEUERUNG[/font_size]

Sende alle Robotereinheiten zum KI-Kern.

Jeder Roboter erhält denselben Auftrag:

execute_task()

Das konkrete Verhalten hängt vom jeweiligen Robotertyp ab.""")

	data_label.append_text(
		"> AUSGEWÄHLT....[color=#15ba12]" + get_selected_bot_name() + "[/color]\n\n" +
		"> RepairBot.....repair()\n\n" +
		"> SecurityBot...secure()\n\n" +
		"> TransportBot..transport()"
	)
	repair_bot_button.visible = false
	security_bot_button.visible = false
	transport_bot_button.visible = false
	
	method_button.visible = true
	method_button.disabled = false
	method_button.text = "EXECUTE TASK()"
	current_method = "send_all_robots"
	
func open_terminal():
	is_open = true
	$Control.visible = true
	player.stun = true
	
	configure_terminal_for_level()
	
	overview_button.grab_focus()
	
	match terminal_level:
		0:
			title_label.clear()
			title_label.append_text("""[font_size=40]TUTORIAL TERMINAL[/font_size]\n[font_size=24]STATION: ECLIPSE-9[/font_size]""")
			MissionManager.complete_subtask("tutorial", "Open terminal with ENTER")
		1: 
			show_title()
			MissionManager.complete_subtask("energy_core", "Open terminal")
		2:
			title_label.clear()
			title_label.append_text("""[font_size=40]SECURITY CONSOLE[/font_size]\n[font_size=24]STATION: ECLIPSE-9[/font_size]""")
			MissionManager.complete_subtask("security_access", "Open security terminal")
		3: 
			title_label.clear()
			title_label.append_text("""[font_size=40]TERMINAL_02[/font_size]\n[font_size=24]STATION: ECLIPSE-9[/font_size]""")
			MissionManager.complete_subtask("robotics", "Open terminal")
		4:
			title_label.clear()
			title_label.append_text("""[font_size=40]TERMINAL_04[/font_size]\n[font_size=24]STATION: ECLIPSE-9[/font_size]""")
			MissionManager.complete_subtask("ai_core", "Open terminal")
	show_overview()
		
func close_terminal():
	is_open = false
	$Control.visible = false
	player.stun = false
	
func configure_terminal_for_level():
	energy_button.visible = terminal_level >= 1
	security_button.visible = terminal_level >= 2
	logs_button.visible = true
	
	if terminal_level == 0:
		overview_button.text = "  1  OVERVIEW"
		logs_button.text = "  2  LOGS"
	
	if terminal_level == 1:
		overview_button.text = "  1  OVERVIEW"
		energy_button.text = "  2  ENERGY"
		security_button.visible = false
		logs_button.text = "  3  LOGS"
	
	if terminal_level == 2:
		overview_button.text = "  1  OVERVIEW"
		energy_button.visible = false
		security_button.text = "  2  SECURITY"
		logs_button.text = "  3  LOGS"
	
	if terminal_level == 3:
		overview_button.text = "  1  OVERVIEW"
		energy_button.text = "  2  ROBOTS"
		security_button.text = "  3  ORDER"
		
	if terminal_level == 4:
		overview_button.text  = "  1  OVERVIEW"
		energy_button.text = "  2  AI-CORE"
		security_button.text = "  3  MISSION"
	
func _update_ping():
	if abs(ping - target_ping) < 3:
		target_ping = randi_range(15, 80)
		
	if ping < target_ping:
		ping += randi_range(1, 3)
	elif ping > target_ping:
		ping -= randi_range(1, 3)
		
	ping_label.text = "PING: " + str(ping) + "ms"
		
	update_signal_from_ping()
	
func _update_signal():
	var signal_strength = randi_range(1, 5)
	for i in range(signal_bars.size()):
		if i < signal_strength:
			signal_bars[i].modulate = Color("#15ba12")
		else:
			signal_bars[i].modulate = Color(0.2, 0.2, 0.2, 1)
	
func update_signal_from_ping():
	var signal_strength := 5
	if ping > 100:
		signal_strength = 1
	elif ping > 80:
		signal_strength = 2
	elif ping > 60:
		signal_strength = 3
	elif ping > 40:
		signal_strength = 4
	
	for i in range(signal_bars.size()):
		if i < signal_strength:
			signal_bars[i].self_modulate = Color("#15ba12")
		else:
			signal_bars[i].self_modulate = Color(0.2, 0.2, 0.2, 1)

func _on_button_hover():
	hover_sound.play()
	
func update_button_highlight():
	repair_bot_button.modulate = Color.WHITE
	security_bot_button.modulate = Color.WHITE
	transport_bot_button.modulate = Color.WHITE
	
	if selected_bot_method == "send_repair_bot":
		repair_bot_button.modulate = Color("#15ba12")
	elif selected_bot_method == "send_security_bot":
		security_bot_button.modulate = Color("#15ba12")
	elif selected_bot_method == "send_transport_bot":
		transport_bot_button.modulate = Color("#15ba12")
		
func is_ai_core_available() -> bool:
	return ai_core != null and ai_core.communication_online
