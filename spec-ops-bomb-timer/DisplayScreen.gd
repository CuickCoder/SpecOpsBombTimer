extends Node
#this script is purely in charge of displaying what it is told to on the 
#bomb timer in the escape room. It shouldn't be handling any game logic

@export var TopTape: Sprite2D
@export var BottomTape: Sprite2D
@export var Background: Sprite2D
@export var scroll_speed := 0.1
@export var TimerLabel: RichTextLabel
@export var AnimPlayer: AnimationPlayer
var MinScrollSpeed = .01
var MaxScrollSpeed = .20
var TexturePosition := 0.0
var timeLeftRatio = 1.0
var backgroundTint = Color.WHITE

func _ready():
	GlobalScript.state_changed.connect(on_state_changed_signal)
	AnimPlayer.play("NEUTRAL_VISUALS")
	pass 
	
func _process(delta):
	#Timer Based Updating of visuals
	if not GlobalScript.BombTimerPaused \
	and GlobalScript.CurrentGameState == GlobalScript.GameState.PLAYING:
		#We need to know what fraction of the Bomb's time is left 
		timeLeftRatio = GlobalScript.BombTimerTimeLeft /GlobalScript.timerStartingAmount
		timeLeftRatio = clamp(timeLeftRatio,0.0,1.0)
		
		#These will use the ratio we found just above
		HandleTapeMovement(delta)
		HandleBackgroundTint()
		HandleTimerShake()
	else: 
		TimerLabel.text = GlobalScript.FormattedTimerText

func HandleTimerShake():
	var baseText = GlobalScript.FormattedTimerText
	#var shakeLevel = int(1 / timeLeftRatio)
	#var shakeRate = int(1 / timeLeftRatio )
	#var adjustedScrollSpeed = lerp(MaxScrollSpeed,MinScrollSpeed,timeLeftRatio)
	
	var shakeLevel = int(lerp(12.0,0.0,timeLeftRatio))
	var shakeRate = int(lerp(25.0,0.0,timeLeftRatio))
	
	print(str(shakeLevel) + " " + str(shakeRate))
	TimerLabel.text = "[shake level=%f rate=%f]%s[/shake]" % [shakeLevel, shakeRate, baseText]
	
	#TimerLabel.text = "[shake level=100 rate=25]YOUR TEXT HERE[/shake]"
	pass

func HandleBackgroundTint():
	backgroundTint = Color(1,timeLeftRatio,timeLeftRatio)
	Background.modulate = backgroundTint

func HandleTapeMovement(delta):
	#Both tapes share a shader, so we only need to update one 
	var adjustedScrollSpeed = lerp(MaxScrollSpeed,MinScrollSpeed,timeLeftRatio)
	TexturePosition = fposmod(TexturePosition + adjustedScrollSpeed * delta, 1.0)
	(TopTape.material as ShaderMaterial).set_shader_parameter("TexturePosition", TexturePosition)

func modulateAll(newColor: Color):
	TopTape.modulate = newColor
	BottomTape.modulate = newColor
	Background.modulate = newColor

func on_state_changed_signal(state: GlobalScript.GameState): 
	match state:
		GlobalScript.GameState.PLAYING:
			AnimPlayer.play("NEUTRAL_VISUALS")
			scroll_speed = MinScrollSpeed
			modulateAll(Color.WHITE)
			
		GlobalScript.GameState.WIN:
			scroll_speed = 0
			AnimPlayer.play("WIN")
			modulateAll(Color.LAWN_GREEN)

		GlobalScript.GameState.LOSE:
			scroll_speed = 0
			AnimPlayer.play("LOSE")
			modulateAll(Color.DARK_RED)
