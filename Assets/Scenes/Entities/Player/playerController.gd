extends Node3D

var time := 0.0
var startPos1
var startPos2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	startPos1 = $skeleton/leftLegTarget.position.y
	startPos2 = $skeleton/rightLegTarget.position.y
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta*10.0
	$skeleton/leftLegTarget.position.y = startPos1+(sin(time)/2.0+0.5)*0.5
	$skeleton/rightLegTarget.position.y = startPos2+(sin(time+PI)/2.0+0.5)*0.5
	pass
