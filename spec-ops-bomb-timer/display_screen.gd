extends Window


#@onready var  timerLabel = $"Bomb Timer Label"
@onready var bombTimer = get_tree().get_root().find_child("Farts")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print(nodget_tree().get_root().getChildren())
	#timerLabel.text = str(bombTimer.time_left)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	pass
