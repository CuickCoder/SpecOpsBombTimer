extends Node
var FormattedTimerText = "00:00"
#WIN: correct wire cut, LOSE: wrong wire cut
#PLAYING: the state for when the timer is wating to be started or 
#when the game is being played
enum GameState {PLAYING,WIN,LOSE}
var CurrentGameState
signal state_changed()

func _ready() -> void:
	#Start in the standby state
	CurrentGameState = GameState.PLAYING
	pass 

func _process(delta: float) -> void:
	pass
