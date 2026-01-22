extends Node
#this script is purely in charge of displaying what it is told to on the 
#bomb timer in the escape room. It shouldn't be handling any game logic

@export var TopTape: Sprite2D
@export var BottomTape: Sprite2D
@export var Background: Sprite2D
#@export var scroll_speed := 0.1
@export var TimerLabel: RichTextLabel
@export var AnimPlayer: AnimationPlayer
var MinScrollSpeed = .01
var MaxScrollSpeed = .35
var TextShakeAmount = 25.0
var TextShakeRate = 25.0
var TexturePosition := 0.0
var backgroundTint = Color.WHITE
var panicModeMinutes = 5
var panicModeStarted = false

func _ready():
	#tapeScrollSpeed = MinScrollSpeed
	GlobalScript.state_changed.connect(on_state_changed_signal)
	AnimPlayer.play("NEUTRAL_VISUALS")

func _process(delta):
	#Figure out what to display based on bombtime & gamestate
	if not GlobalScript.BombTimerPaused \
	and GlobalScript.CurrentGameState == GlobalScript.GameState.PLAYING:
		#Display the normal timer screen if we haven't hit panic mode yet
		if GlobalScript.BombTimerTimeLeft > (panicModeMinutes * 60) \
		and not panicModeStarted:
			HandleNormalMode(delta)
		#Timer is below panic mode threshold, do panic mode
		else:
			HandlePanicMode(delta)
	#Timer is paused and reset, display the correct time for the game master
	else:
		TimerLabel.text = GlobalScript.FormattedTimerText

func HandleNormalMode(delta):
	HandleTapeMovement(delta, MinScrollSpeed)
	TimerLabel.text = GlobalScript.FormattedTimerText
	pass

func HandlePanicMode(delta):
	#Do these once per panic mode
	if not panicModeStarted:
		AnimPlayer.play("PANIC_MODE") 
		panicModeStarted = true
	
	var baseText = GlobalScript.FormattedTimerText
	TimerLabel.text = "[shake level=%f rate=%f]%s[/shake]" % [TextShakeAmount, TextShakeRate, baseText]
	Background.modulate = Color.RED
	HandleTapeMovement(delta, MaxScrollSpeed)
	

func HandleTapeMovement(delta, scrollSpeed):
	#Both tapes share a shader, so we only need to update one 
	if GlobalScript.BombTimerPaused: 
		return #Tape shouldn't move at all if timer is paused
	
	TexturePosition = fposmod(TexturePosition + scrollSpeed * delta, 1.0)
	(TopTape.material as ShaderMaterial).set_shader_parameter("TexturePosition", TexturePosition)

func on_state_changed_signal(state: GlobalScript.GameState): 
	match state:
		GlobalScript.GameState.PLAYING:
			panicModeStarted = false
			AnimPlayer.play("NEUTRAL_VISUALS")
			#scroll_speed = MinScrollSpeed
			Background.modulate = (Color.WHITE)
			
		GlobalScript.GameState.WIN:
			#scroll_speed = 0
			AnimPlayer.play("WIN")
			Background.modulate = (Color.LAWN_GREEN)
			
		GlobalScript.GameState.LOSE:
			#scroll_speed = 0
			AnimPlayer.play("LOSE")
			Background.modulate = (Color.DARK_RED)
