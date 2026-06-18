extends Node2D

@onready var player = $"../Player"
@onready var dialogbox = $"../Dialogbox"
@onready var inventory = $"../Inventory"
@onready var minimap = $"../MiniMap"
@onready var terminal = $"../Terminal"
@onready var object = $"../TutorialObject"
@onready var boot_screen = $"../BootScreen"
@onready var wake_fade = $"../WakeFade/ColorRect"
@onready var camera = $"../Player/Camera2D"

@export var cryopod_path : NodePath
@onready var cryopod = get_node_or_null(cryopod_path)

@export var door_path : NodePath
@onready var door = get_node_or_null(door_path)

@export var ambient_music_path : NodePath
@onready var ambient_music = get_node_or_null(ambient_music_path)

@onready var boot_sound = $BootSound
@onready var waking_up_sound = $WakingUpSound

var waiting_for_movement := false
var waiting_for_menu := false
var waiting_for_inventory := false
var waiting_for_navigation := false
var waiting_for_minimap := false
var waiting_for_terminal := false
var waiting_for_object_pickup := false
var waiting_for_object_drop := false

var task := "tutorial"

func _ready():
	if ambient_music != null:
		ambient_music.play()
		
	get_tree().paused = true
	wake_fade.visible = false
	boot_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	boot_sound.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stun = true
	boot_screen.visible = true
	boot_sound.play()
	
	await get_tree().process_frame

	await boot_screen.typing("> SYSTEM REBOOTING...")
	await get_tree().create_timer(0.5).timeout
	await boot_screen.glitch()
	await boot_screen.typing("> MEMORY MODULE...........OK")
	await get_tree().create_timer(0.3).timeout
	await boot_screen.typing("> SENSOR ARRAY............ERROR")
	await get_tree().create_timer(0.5)
	await boot_screen.glitch()
	await boot_screen.typing("> RECOVERING..............OK")
	await get_tree().create_timer(0.6).timeout
	await boot_screen.typing("> PLAYER INPUT............OK")
	await get_tree().create_timer(0.4).timeout
	await boot_screen.glitch()
	await boot_screen.typing("> MISSION SYSTEM..........ONLINE")
	await get_tree().create_timer(0.5).timeout
	await boot_screen.typing("> DEEP SPACE DEBUGGER.....READY")
	await boot_screen.glitch()
	await get_tree().create_timer(1.0).timeout
	
	boot_sound.stop()
	boot_screen.visible = false
	get_tree().paused = false
	
	if ambient_music != null:
		waking_up_sound.play()
		ambient_music.play()
	
	wake_fade.visible = true
	wake_fade.modulate.a = 1.0
	await get_tree().create_timer(1.0).timeout
	
	cryopod.open_pod()
	wake_fade.color = Color.WHITE
	
	var tween = create_tween()
	tween.tween_property(wake_fade, "modulate:a", 0.0, 0.75)
	var original_offset = camera.offset
	camera.offset = Vector2(4, 0)
	await get_tree().create_timer(0.05).timeout
	camera.offset = Vector2(-4, 0)
	await get_tree().create_timer(0.075).timeout
	camera.offset = original_offset
	
	await tween.finished
	wake_fade.visible = false
	
	dialogbox.show_dialog("Vitals stable.\n\n" + "Cryostasis terminated.\n\n" + "Welcome back, Engineer.")
	await get_tree().create_timer(5.0).timeout
	dialogbox.show_dialog("Primary objective:\n" +"Restore station functionality.")
	await get_tree().create_timer(5.0).timeout
	dialogbox.show_dialog("Check the Mission Status to proceed.")
	waiting_for_movement = true

func _process(_delta):
	if waiting_for_movement:
		if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
			waiting_for_movement = false
			player.stun = false
			MissionManager.complete_subtask(task, "Press any movement key")
			waiting_for_menu = true
	elif waiting_for_menu:
		if Input.is_action_just_pressed("ui_cancel"):
			waiting_for_menu = false
			MissionManager.complete_subtask(task, "Open menu with ESC")
			waiting_for_inventory = true
	elif waiting_for_inventory:
		if Input.is_action_just_pressed("inventory"):
			waiting_for_inventory = false
			MissionManager.complete_subtask(task, "Open the inventory with I")
			waiting_for_navigation = true
	elif waiting_for_navigation:
		if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
			waiting_for_navigation = false
			MissionManager.complete_subtask(task, "Navigate with Up and Down")
			waiting_for_minimap = true
	elif waiting_for_minimap:
		if Input.is_action_just_pressed("map"):
			waiting_for_minimap = false
			MissionManager.complete_subtask(task, "Open the minimap with M")
			waiting_for_terminal = true
	elif waiting_for_terminal:
		if terminal.is_open:
			waiting_for_terminal = false
			MissionManager.complete_subtask(task, "Open terminal with ENTER")
			waiting_for_object_pickup = true
	elif waiting_for_object_pickup:
		if inventory.was_picked_up:
			waiting_for_object_pickup = false
			MissionManager.complete_subtask(task, "Pick up object")
			waiting_for_object_drop = true
	elif waiting_for_object_drop:
		if inventory.was_dropped:
			waiting_for_object_drop = false
			MissionManager.complete_subtask(task, "Drop object")
			await get_tree().create_timer(2.0).timeout
			door.open_door()
