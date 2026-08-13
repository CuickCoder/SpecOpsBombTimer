extends Control
# This script handles the control-screen buttons, updates the timer based on
# user input, and controls which actions are available based on the game state
# and the bridge/Arduino connection state. In a future update, it will also
# give you compliments.

@export var BOMB_CONNECTED_COLOR: Color
@export var BOMB_NOT_CONNECTED_COLOR: Color

@export var BombTimerNode: Timer 
@export var RawTimerNodeLabel: Label 
@export var FormattedTimerLabel: Label 
@export var Add_Subtract_Field:LineEdit 
@export var CustomTimeFieldMinutes: LineEdit 
@export var CustomTimerFieldSeconds:LineEdit 
@export var ResetTimerButton: Button 
@export var CorrectWireButton: Button 
@export var WrongWireButton: Button
@export var PlayPauseButton: Button
@export var CloseTimerButton: Button
@export var UseArduinoInputCheckbox : CheckBox
@export var WinLoseBehaviorLabel : Label
@export var BombConnectionLabel: Label

var DisplayScreen = preload("res://Scenes/DisplayScreen.tscn")
var DefaultStartingTime = 3300.00
var physcial_wire_already_detected = false

func _ready() -> void:
	#setup the timer
	print("hello from control_screen.gd ready()")
	ArduinoScript.arduino_message_received.connect(_on_arduino_message)
	BombTimerNode.start(DefaultStartingTime)
	BombTimerNode.paused = true
	#Update Global Script
	updateGlobalScript()

func _process(delta: float) -> void:
	#Update the text on screen to show how much time is on timer
	RawTimerNodeLabel.text = str(BombTimerNode.time_left)
	FormattedTimerLabel.text = convert_timer_to_MMSS_string(BombTimerNode.time_left)
	
	#ALL ARDUINO RELATED STUFF --------------------------
	#Disable the USB input checkbox if ArduinoScript's ConnectionState is not USB_READY
	if ArduinoScript.CurrentConnectionState == ArduinoScript.ConnectionState.USB_DISCONNECTED:
		UseArduinoInputCheckbox.disabled = true
	else: 
		UseArduinoInputCheckbox.disabled = false
	
	#update the connection status message from the Arduino Script to show on control screen
	BombConnectionLabel.text = ArduinoScript.connection_message
	if ArduinoScript.CurrentConnectionState == ArduinoScript.ConnectionState.USB_READY: 
		BombConnectionLabel.add_theme_color_override("font_color", BOMB_CONNECTED_COLOR)
	else: 
		BombConnectionLabel.add_theme_color_override("font_color", BOMB_NOT_CONNECTED_COLOR)

	#tell the user what mode is active
	if physcial_wire_already_detected: 
			WinLoseBehaviorLabel.text = "MANUAL MODE: reset timer & replace wire to enable AUTO MODE"
			WinLoseBehaviorLabel.add_theme_color_override("font_color", BOMB_NOT_CONNECTED_COLOR)
	elif UseArduinoInputCheckbox.button_pressed \
		and ArduinoScript.CurrentConnectionState == ArduinoScript.ConnectionState.USB_READY :
		WinLoseBehaviorLabel.text = "AUTO MODE"
		WinLoseBehaviorLabel.add_theme_color_override("font_color", BOMB_CONNECTED_COLOR)
	else: 
		WinLoseBehaviorLabel.text = "MANUAL MODE"
		WinLoseBehaviorLabel.add_theme_color_override("font_color", BOMB_NOT_CONNECTED_COLOR)

	#-----------------------------------------------------

	#Don't allow the timer reset or close window buttons to
	#be pressed if timer is running
	if BombTimerNode.paused or BombTimerNode.time_left == 0.0: 
		ResetTimerButton.disabled = false
		CloseTimerButton.disabled = false
	else: 
		CloseTimerButton.disabled = true
		ResetTimerButton.disabled = true
	
	updateGlobalScript()

func updateGlobalScript():
	GlobalScript.FormattedTimerText = FormattedTimerLabel.text
	GlobalScript.BombTimerTimeLeft = BombTimerNode.time_left
	GlobalScript.BombTimerPaused = BombTimerNode.paused

func Play_or_Pause_timer():
	#return to the playing state in case a WIN or LOSE state was accidentally triggered
	GlobalScript.change_game_state("PLAYING")

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
		
		#Reset the game state!
		GlobalScript.change_game_state("PLAYING")
		CorrectWireButton.disabled = false 
		WrongWireButton.disabled = false
		PlayPauseButton.disabled = false
		
		#make arduino_input usable again
		physcial_wire_already_detected = false

func convert_timer_to_MMSS_string(time_left: float) -> String:
	var total_seconds := int(time_left)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func adjust_timer(mode: String):
	#this is the function that actually changes the timer
	
	var new_time #the new time to set, this will get set in the match statement
	
	match mode: 
		"ADDSUBTRACT": #add to timer from Add_SubTract_Field
			#ignore invalid input
			if not Add_Subtract_Field.text.is_valid_int(): 
				Add_Subtract_Field.text = "NaN"
				return
			#input from this field is in minutes, grab it and convert to seconds
			var timeToAdd = Add_Subtract_Field.text.to_float() * 60
			new_time = BombTimerNode.time_left + timeToAdd
			new_time = max(new_time, 0.0) #returns the larger arg, prevents negative timers
			
		"CUSTOMTIME": #sets the timer to the custom time entered by the user
			#ignore invalid input 
			if not CustomTimeFieldMinutes.text.is_valid_int() \
			or not CustomTimerFieldSeconds.text.is_valid_int(): 
				CustomTimeFieldMinutes.text = "NaN"
				CustomTimerFieldSeconds.text = "NaN"
				return
			elif CustomTimerFieldSeconds.text.to_float() > 59: 
				print("seconds too high!")
				return
			#grab time from both fields and combine into one float as seconds
			new_time = CustomTimeFieldMinutes.text.to_float() * 60
			new_time += CustomTimerFieldSeconds.text.to_float()
		_: 
			print("adjust_timer() expected ADDSUBTRACT or CUSTOMTIME,\
			 was given '" + mode + "' instead.")
			return
	
	var was_paused = BombTimerNode.paused #store timer state cuz we're about to change it
	BombTimerNode.stop() #cant change time on a running timer
	BombTimerNode.start(new_time) #can only change time on timer when you start it 
	BombTimerNode.paused = was_paused #returns timer to the state it was already in

func ADD_OR_SUBTRACT_FROM_FIELD(mode: String): 
	#This function DOES NOT TOUCH THE TIMER it only adds
	#or subtracts from the number in the field that the 
	#user can type input into. The text in that field 
	#is then passed when another button calls adjust_timer()
	
	#ignore invalid user input in the field 
	if not Add_Subtract_Field.text.is_valid_int():
		Add_Subtract_Field.text = "0"
		return
	
	#grab the user input then convert to an int
	var text = Add_Subtract_Field.text.strip_edges()
	text = text.to_int()
	
	#add or subtract depending on which button was pressed
	match mode: 
		"ADD":text += 1 #argument passed by add button
		"SUBTRACT": text -=1 #argument passed by subtract button
		_: print("ADD_OR_SUBTRACT_FROM_FIELD() expected ADD or SUBTRACT,\
		 was given '" + mode + "' instead")
	
	#change the field's text to match the result
	Add_Subtract_Field.text = str(text)

func wire_button_pressed(newstate: String):
	BombTimerNode.paused = true
	#PlayPauseButton.disabled = true
	GlobalScript.change_game_state(newstate)

func _on_arduino_message(message: String) -> void:
	#this is called when ArduinoScript emits a message received from the Arduino

	#Only activate Win/Lose if the USB is connected, we haven't already cut a wire, 
	#and if the checkbox is checked
	if UseArduinoInputCheckbox.button_pressed and not physcial_wire_already_detected \
	and ArduinoScript.CurrentConnectionState == ArduinoScript.ConnectionState.USB_READY:
		if message.begins_with("GOOD_WIRE"):
			physcial_wire_already_detected = true
			wire_button_pressed("WIN")
		elif message.begins_with("BAD_WIRE"):
			physcial_wire_already_detected = true
			wire_button_pressed("LOSE")

func openTimerDisplayWindow():
	if not get_tree().root.has_node("DisplayScreen"):
		var DisplayScreenWindow = DisplayScreen.instantiate()
		DisplayScreenWindow.position = get_window().position
		get_tree().root.add_child(DisplayScreenWindow)

func close_timer_window_button_pressed():
	GlobalScript.close_display_button_pressed.emit()
	pass
