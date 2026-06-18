extends Node2D

@onready var opening_sound = $OpenSound

func open_pod():
	opening_sound.play()
