extends Node
#this script is purely in charge of displaying what it is told to on the 
#bomb timer in the escape room. It shouldn't be handling any game logic

@export var TopTape: Sprite2D
@export var scroll_speed := 0.25
@export var TimerLabel: RichTextLabel

var TexturePosition := 0.0

func _ready():
	pass 
	
func _process(delta):
	TimerLabel.text = GlobalScript.FormattedTimerText
	HandleTapeMovement(delta)

func HandleTapeMovement(delta):
	#Both tapes share a shader, we only need to update one 
	#The bottom tape has "Flip H" set to "on" so it goes in the other direction
	TexturePosition = fposmod(TexturePosition + scroll_speed * delta, 1.0)
	(TopTape.material as ShaderMaterial).set_shader_parameter("TexturePosition", TexturePosition)
