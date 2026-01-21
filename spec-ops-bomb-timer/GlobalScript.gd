extends Node
#This script is not intended to contain logic, all of the logic and
#number crunching is to be put into the control screen script. 
#this script is purely here to hold and pass variables

var FormattedTimerText = "00:00"
var BombTimerTimeLeft = 0
var BombTimerPaused = true
var timerStartingAmount = 3300 #this is a placeholder
enum GameState {PLAYING,WIN,LOSE} #PLAYING is also used as an idle state
var CurrentGameState = GameState.PLAYING
signal state_changed(new_state)


func _ready() -> void:
	#Start in the standby state
	CurrentGameState = GameState.PLAYING
	pass 

func _process(delta: float) -> void:
	pass

func change_game_state(newState: String):
	CurrentGameState = GameState[newState]
	state_changed.emit(CurrentGameState)
	#print("global script emitted signal")
