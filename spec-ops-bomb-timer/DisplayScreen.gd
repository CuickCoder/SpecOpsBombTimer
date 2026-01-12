extends Node2D
@onready var bombTimerLabel = $"Bomb Timer Label"
@onready var BombTimerTextSource = get_tree().get_root().get_node("Farts")\
.get_node("BombTimerNode").get_node("FormattedTimerLabel")
func _ready() -> void:
	print(get_tree().get_root().get_node("Farts").get_node("BombTimerNode"))
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	bombTimerLabel.text = BombTimerTextSource.text
	pass
