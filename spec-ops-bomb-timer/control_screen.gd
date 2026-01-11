extends Node2D
@onready var BombTimerNode = $BombTimerNode
@onready var RawTimerNodeLabel = $BombTimerNode/RawTimerLabel
@onready var FormattedTimerLabel = $BombTimerNode/FormattedTimerLabel
@onready var Add_Subtract_Field = $Add_Subtract_Field
var DisplayScreen = preload("res://DisplayScreen.tscn")
var DefaultStartingTime = 3600.00

func _ready() -> void:
	reset_timer() #otherwise the timer will display as 0

func _process(delta: float) -> void:
	RawTimerNodeLabel.text = str(BombTimerNode.time_left)
	FormattedTimerLabel.text = convert_timer_to_MMSS(BombTimerNode.time_left)

func Play_or_Pause_timer():
	#is_stoppped returns true if timer hasn't been started yet
	if BombTimerNode.is_stopped():
		BombTimerNode.start()
	else:
		#toggle the bool "paused" if timer has already been started
		BombTimerNode.paused = not BombTimerNode.paused

func reset_timer():
	#so the user can't accidentally restart a timer during a game
	if BombTimerNode.is_stopped() or BombTimerNode.paused:
		#godot timers can't have any seconds unless it was started or has been paused
		BombTimerNode.start(DefaultStartingTime)
		BombTimerNode.paused = true

func convert_timer_to_MMSS(time_left: float) -> String:
	var total_seconds := int(time_left)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func adjust_timer():
	var amount_text = Add_Subtract_Field.text
	var timeToAdd = amount_text.to_float() * 60.00

	# Ignore invalid input
	if timeToAdd == 0.0 and amount_text.strip_edges() != "0":
		Add_Subtract_Field.text = "ENTER NUMBER"
		return

	var new_time = BombTimerNode.time_left + timeToAdd
	new_time = max(new_time, 0.0)

	#we'll want to return timer to paused state if it was paused
	var was_paused = BombTimerNode.paused
	BombTimerNode.stop()
	BombTimerNode.start(new_time)
	BombTimerNode.paused = was_paused

func createNewWindow():
	var newWindow = DisplayScreen.instantiate()
	get_tree().root.add_child(newWindow)

func adjust_field_by_one(mode: String): 
	var text = Add_Subtract_Field.text.strip_edges()
	text = text.to_int()

	# Ignore invalid input
	if text == 0 and text.strip_edges() != "0":
		Add_Subtract_Field.text = "ENTER NUMBER"
		return
		
	match mode: 
		"ADD": text += 1 
		"SUBTRACT": text -=1
		_:
			print(str(mode) + " is not a valid mode for this function")
