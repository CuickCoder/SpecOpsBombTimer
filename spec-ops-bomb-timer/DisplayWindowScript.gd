extends Window
#This script is purely meant to handle the settings for the 
#window node that contains the display screen. The window settings
#set up

func _ready():
	content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	content_scale_size = size  # 👈 use the window’s initial size

func _on_close_requested() -> void:
	#the X button on the timer screen doesn't do diddly unless you
	#connect it to a function that closes it
	queue_free() #unalive_self()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click:
		if mode == Window.MODE_FULLSCREEN:
			mode = Window.MODE_WINDOWED
		else:
			mode = Window.MODE_FULLSCREEN
