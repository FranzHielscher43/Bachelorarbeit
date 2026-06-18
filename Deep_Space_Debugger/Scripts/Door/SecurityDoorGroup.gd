extends Node2D

@onready var door = $Door

func unlock_by_security_bot():
	door.unlock_by_security_bot()
