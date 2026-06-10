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
	
func _on_method_pressed():
	click_sound.play()
	await  click_sound.finished
	
	match current_method:
		"start_robot":
			execute_start_robot()

	close_terminal()
	
func execute_start_robot():
	var robot = get_tree().get_first_node_in_group("Robot")
	if robot != null:
		await get_tree().create_timer(2.0).timeout
		robot.start_robot()
		MissionManager.complete_subtask("start_robot", "Startknopf betätigen")
		complete_methods["start_robot"] = true
		method_button.disabled = true
		method_button.text = "ROBOTER AKTIVIERT"
		current_method = ""
	
func show_title():
	title_label.clear()
	title_label.append_text("""[font_size=40]TERMINAL_01[/font_size]\n[font_size=24]STATION: ECLIPSE-9[/font_size]""")
	
func show_overview():
	info_label.clear()
	info_label.append_text("""[font_size=24]STATIONSÜBERSICHT[/font_size]\n\nWillkommen im Stationsverwaltungssystem.\n\nDie Station wird durch verschiedene Software- und Hardwaresysteme gesteuert. Alle Systeme werden als Objekte verwaltet und besitzen eigene Eigenschaften und Funktionen.\n\nTipp:\nNicht jedes Objekt besitzt die benötigten Eigenschaften für die aktuelle Aufgabe!""")
	data_label.clear()
	data_label.append_text("""> STATUS........[color=#15ba12]AKTIV[/color]\n\n> SEKTOR........B-03\n\n> ENERGIE.......[color=#ff4d4d]INSTABIL[/color]\n\n> SICHERHEIT....[color=#ff4d4d]INAKTIV[/color]\n\n> AUFGABE.......[color=#f7c948]ENERGIEKERN FINDEN[/color]""")
	
	if complete_methods.has("start_robot"):
		method_button.disabled = true
		method_button.text = "ROBOTER AKTIVIERT"
		method_button.visible = true
	else:
		current_method = "start_robot"
		method_button.text = "ROBOTER STARTEN"
		method_button.disabled = false
		method_button.visible = true
	
func show_energy():
	info_label.clear()
	info_label.append_text("""[font_size=24]ENERGIESYSTEM[/font_size]\n\nDas Energiesystem versorgt sämtliche Stationseinheiten mit Strom.\n\nFür die Aktivierung eines Generators wird ein kompatibler Energiekern benötigt.\n\nJeder Energiekern besitzt individuelle Attribute, welche seine Eignung bestimmen.\n\nTipp:\nÜberprüfe die Eigenschaften gefundener Objekte sorgfältig, bevor du sie einsetzt.""")
	data_label.clear()
	data_label.append_text("""> SYSTEM........GENERATOR_A\n\n> STATUS........[color=#ff4d4d]OFFLINE[/color]\n\n> LEISTUNG......[color=#ff4d4d]0%[/color]\n\n> KLASSE........[color=#f7c948]EnergyCore[/color]\n\n> ATTRIBUT......[color=#f7c948]charged = true[/color]\n\n> ATTRIBUT......[color=#f7c948]power >= 50[/color]\n\n> MODUL.........[color=#f7c948]NICHT EINGESETZT[/color]""")
	
	method_button.visible = false

func show_security():
	info_label.clear()
	info_label.append_text("""[font_size=24]SICHERHEITSSYSTEM[/font_size]\n\nDas Sicherheitssystem überwacht kritische Stationsbereiche und kontrolliert den Zugang zu gesperrten Sektoren.\n\nViele Sicherheitseinrichtungen reagieren auf den Zustand anderer Objekte innerhalb der Station.\n\nTipp:\nManche Systeme können erst aktiviert werden, wenn zuvor andere Bedingungen erfüllt wurden.""")
	data_label.clear()
	data_label.append_text("""> SYSTEM........LABORZUGANG_01\n\n> STATUS........[color=#ff4d4d]GESPERRT[/color]\n\n> ABHÄNGIGKEIT..[color=#ff4d4d]Generator_A[/color]\n\n> METHODE.......[color=#ff4d4d]open_door()[/color]\n\n> FREIGABE......[color=#f7c948]AUSSTEHEND[/color]\n\n> HINWEIS.......[color=#f7c948]ENERGIEVERSORGUNG FEHLT[/color]""")

	method_button.visible = false

func show_logs():
	info_label.clear()
	info_label.append_text("""[font_size=24]SYSTEMPROTOKOLLE[/font_size]\n\nDie Protokolle dokumentieren wichtige Ereignisse und Zustandsänderungen innerhalb der Station.\n\nSie können wertvolle Hinweise auf aktuelle Probleme sowie deren mögliche Ursachen liefern.\n\nTipp:\nAnalysiere die Reihenfolge der Einträge, um Zusammenhänge zwischen einzelnen Systemen zu erkennen.""")
	data_label.clear()
	data_label.append_text("""> [10:41] [color=#15ba12]SYSTEMSTART[/color]\n\n> [10:42] [color=#ff4d4d]ENERGIEFEHLER ERKANNT[/color]\n\n> [10:42] [color=#ff4d4d]GENERATOR_A DEAKTIVIERT[/color]\n\n> [10:43] [color=#ff4d4d]LABORZUGANG VERRIEGELT[/color]\n\n> [10:44] [color=#15ba12]WARTUNGSMODUS AKTIV[/color]\n\n> [10:45] [color=#f7c948]SUCHE NACH KOMPATIBLEM MODUL[/color]""")

	method_button.visible = false

func open_terminal():
	is_open = true
	$Control.visible = true
	player.stun = true
	overview_button.grab_focus()
	show_title()
	show_overview()
	
	MissionManager.complete_subtask("start_robot", "Terminal öffnen")
	
func close_terminal():
	is_open = false
	$Control.visible = false
	player.stun = false
	
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
