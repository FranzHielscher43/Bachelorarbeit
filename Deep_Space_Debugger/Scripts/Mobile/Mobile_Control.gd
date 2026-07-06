extends CanvasLayer

func _ready():
	visible = OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()
