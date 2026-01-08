extends Node2D
@onready var bombTimerLabel = $"Bomb Timer Label"
@onready var BombTimerNode = get_tree().get_root().get_node("Farts").get_node("BombTimerNode")
func _ready() -> void:
	print(get_tree().get_root().get_node("Farts").get_node("BombTimerNode"))
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	bombTimerLabel.text = str(BombTimerNode.time_left)
	pass
