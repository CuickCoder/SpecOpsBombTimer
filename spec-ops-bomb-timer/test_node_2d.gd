extends Node

var phase := 0.0
var speed := 0.35   # try changing this, even to negative

func _process(delta):
	phase = fposmod(phase + speed * delta, 1.0)
	print(phase)
