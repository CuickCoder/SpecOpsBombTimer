extends Node
#This script is not intended to contain logic, all of the logic and
#number crunching is to be put into the control screen script. 
#this script is purely here to hold and pass variables

var FormattedTimerText = "00:00"
var BombTimerTimeLeft = 0
var BombTimerPaused = true
enum GameState {PLAYING,WIN,LOSE} #PLAYING also used as idle state
var CurrentGameState = GameState.PLAYING
signal state_changed(new_state)
signal close_display_button_pressed()

func _ready() -> void:
	#Start in the standby state
	CurrentGameState = GameState.PLAYING
	pass 

func change_game_state(newState: String):
	CurrentGameState = GameState[newState]
	state_changed.emit(CurrentGameState)
