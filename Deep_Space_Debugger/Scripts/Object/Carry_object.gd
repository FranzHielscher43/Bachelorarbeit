extends Area2D

# Dialogfeld - Inhalt
@export var core_texture: AtlasTexture
@export var object_name := ""
@export var class_name_display := ""
@export var attributes := {
	"capacity": "0",
	"stability": "0",
	"state": "stable"
}

@onready var dialog_box = $"../Dialogbox" 

@export var item_id := "object_1"
@onready var sprite = $Sprite2D
@onready var pick_up_sound = $PickUpSound
@onready var drop_down_sound = $DropDownSound

@onready var inventory = $"../Inventory"

@export var is_carryable := true

var original_scale : Vector2

var player_nearby := false
var current_player = null

var is_placed := false

var examined := false

func _ready():
	if core_texture != null:
		sprite.texture = core_texture
		
	original_scale = sprite.scale
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("ui_accept") and is_carryable:
		pick_up()
	elif player_nearby and Input.is_action_just_pressed("ui_accept") and !is_carryable:
		dialog_box.show_dialog("This object is too heavy to carry.\nLook for another way to move it.", true, "Too Heavy")
				
	if player_nearby:
		var pulse = 0.7 + sin(Time.get_ticks_msec() * 0.005) * 0.3
		sprite.modulate = Color.WHITE.lerp(Color(1.5, 1.5, 1.5, 1.0), pulse)
	else:
		sprite.modulate = Color.WHITE

func pick_up():
	if current_player == null:
		return
		
	if inventory.items.size() >= 5:
		return
	
	inventory.add_item(get_inventory_data())
	pick_up_sound.play()
	dialog_box.hide_dialog()
	visible = false
	set_process(false)
	$CollisionShape2D.disabled = true

func set_carried_by_bot(_bot):
	visible = true
	set_process(false)
	$CollisionShape2D.disabled = true
	player_nearby = false
	current_player = null
	dialog_box.hide_dialog()
	
func set_place_by_bot(pos: Vector2):
	global_position = pos
	visible = true
	$CollisionShape2D.disabled = false
	set_process(true)
	set_placed()

func _on_body_entered(body):
	if is_placed:
		return
		
	if body.name == "Player":
		player_nearby = true
		current_player = body
		show_attributes()
		
		if !examined:
			examined = true
			MissionManager.complete_subtask("energy_core", "Examine energy cores")

func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
		current_player = null
		dialog_box.hide_dialog()

func get_item_id():
	return item_id

func get_inventory_data():
	return {
		"id": item_id,
		"name": object_name,
		"class": class_name_display,
		"attributes": attributes,
		"texture": sprite.texture,
		"object": self
	}
	
func show_attributes():
	var info_text = "Object: " + object_name + "\n"
	info_text += "Class: " + class_name_display + "\n"
	
	var lines := []
	
	for key in attributes.keys():
		lines.append("• " + key + " = " + str(attributes[key]))
	
	info_text += "Attributes:\n"
	info_text += "\n".join(lines)
	dialog_box.show_dialog(info_text)

func set_placed():
	is_placed = true
	player_nearby = false
	current_player = null
	sprite.modulate = Color.WHITE
	set_process(false)
	dialog_box.hide_dialog()
