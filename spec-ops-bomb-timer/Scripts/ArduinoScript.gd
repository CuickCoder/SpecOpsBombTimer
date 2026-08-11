extends Node
# This script receives bridge and Arduino messages over UDP, tracks the current
# connection state, and emits Arduino messages for other scripts to interpret

signal arduino_message_received(message: String)

enum ConnectionState {
	USB_READY,
	USB_DISCONNECTED,
}

const BRIDGE_PORT := 4242
const CONNECTION_TIMEOUT_COUNTDOWN := 3000
var udp_listener := PacketPeerUDP.new()
var connection_message := "Bridge Program Not running."
var last_bridge_message_time := -CONNECTION_TIMEOUT_COUNTDOWN 
var last_arduino_message_time := -CONNECTION_TIMEOUT_COUNTDOWN
var CurrentConnectionState = ConnectionState.USB_DISCONNECTED

func _ready() -> void:
	print("greetings from the ArduinoScript.gd _ready()")

	#tell the UDP object (udp_listener) to listen for bridge messages sent to this computer
	#on 127.0.0.1 using the port number stored in BRIDGE_PORT
	#bind() returns an error code that tells us whether it was successful
	var error := udp_listener.bind(BRIDGE_PORT, "127.0.0.1")

	#if the port was opened successfully, confirm that we are listening
	if error == OK:
		print("ArduinoScript.gd _ready(): Listening for udp_listener on port ", BRIDGE_PORT)
	#if it failed, report the error in Godot's debugger
	else:
		push_error("ArduinoScript.gd _ready(): Could not listen on udp_listener port %d" % BRIDGE_PORT)


func _process(_delta: float) -> void:
	
	#enter a loop if there are unread packets waiting
	while udp_listener.get_available_packet_count() > 0:
		
		#grabs the next packet and converts it to a string that godot can read
		var message := udp_listener.get_packet().get_string_from_utf8()
		
		#sends that message fromm the packet to handle_bridge_message so godot 
		#can respond to it
		handle_bridge_message(message)

		#loop then repeats for all remaining packets

	#this gets called in handle_bridge_message, but we need to call it here 
	#in case there is a drought of messages from the udp_listener
	update_connection_state()


func handle_bridge_message(message: String) -> void:
	var cleaned_message := message.strip_edges()
	var current_time := Time.get_ticks_msec()
	#if we are in this function, that means we heard from the udp_listener, and can report
	#the current time as the time we last heard from it
	last_bridge_message_time = current_time

	#if we have the udp_listener, but no arduino, subtract from arduino timeout countdown
	if cleaned_message == "BRIDGE_NO_ARDUINO":
		last_arduino_message_time = -CONNECTION_TIMEOUT_COUNTDOWN

	#if the Arduino sent its connection check, then reset the Arduino countdown
	elif cleaned_message == "ARDUINO_CONNECTION_CHECK":
		last_arduino_message_time = current_time

	#BRIDGE_CONNECTED is only a bridge status update, so there is nothing else to do
	elif cleaned_message == "BRIDGE_CONNECTED":
		pass

	#send all other Arduino messages to whichever project script wants to interpret them
	else:
		arduino_message_received.emit(cleaned_message)

	update_connection_state()


func update_connection_state() -> void:
	#grab the current time
	var current_time := Time.get_ticks_msec()

	#if the udp_listener hasn't timed out...
	if current_time - last_bridge_message_time < CONNECTION_TIMEOUT_COUNTDOWN: 
		#...and the arduino hasn't timed out:
		if current_time - last_arduino_message_time < CONNECTION_TIMEOUT_COUNTDOWN:
			#then all is connected, set to USB_READY
			CurrentConnectionState = ConnectionState.USB_READY
			connection_message = "Connected to Game!"
		#...but the arduino timed out
		else: 
			CurrentConnectionState = ConnectionState.USB_DISCONNECTED
			connection_message = "Bridge Program running, USB disconnected"
	#but if the udp_listener has timed out...
	else: 
		CurrentConnectionState = ConnectionState.USB_DISCONNECTED
		connection_message = "Bridge Program Not running"
