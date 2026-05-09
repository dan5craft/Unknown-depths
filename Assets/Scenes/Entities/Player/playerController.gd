extends Node3D

var time := 0.0
@export var legs:Array[Node3D]
@export var arms:Array[Node3D]
var legStartPositions:Array[Vector3]
var armStartPositions:Array[Vector3]
var startPosition:Vector3


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	startPosition = position
	for leg in legs:
		legStartPositions.append(leg.position)
	for arm in arms:
		armStartPositions.append(arm.position)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta*0.1
	var sum := Vector3(0.0, 0.0, 0.0)
	for leg in legs:
		sum += leg.position
	var center:Vector3 = sum/legs.size()
	var radius:float = (legs[0].position-center).length()
	var dist = (global_position-center).length()
	if(dist > radius):
		var furthestLeg := legs[0]
		var furthestLegIndex := 0
		for i in range(legs.size()):
			var leg = legs[i]
			if (leg.position-global_position).length() > (furthestLeg.position-global_position).length():
				furthestLeg = leg
				furthestLegIndex = i
		furthestLeg.position = legStartPositions[furthestLegIndex]+global_position
	position.x = cos(time)*10.0
	position.z = sin(time)*10.0
	pass
