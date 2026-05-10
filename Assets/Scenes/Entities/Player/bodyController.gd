extends Node3D

var time := 0.0
@export var legs:Array[Leg]
@export var armMarkers:Array[Node3D]
@export var body:Node3D
var speed = 0.1
var walkRadius = 10.0
var lastPos:Vector3
var lastPosTime:int

func castRay(pos1:Vector3, pos2:Vector3) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(pos1, pos2)
	return space_state.intersect_ray(query)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta*speed
	body.global_position.x = cos(time)*walkRadius
	body.global_position.z = sin(time)*walkRadius
	var v = Vector3(cos(time+PI/2.0), 0.0, sin(time+PI/2.0))*walkRadius*delta*speed*200.0
	var lowest:Leg = legs[0]
	var furthest:Leg = legs[0]
	for leg in legs:
		if leg.dist() > furthest.dist():
			furthest = leg
		leg.move()
		if leg.global_position.y < lowest.global_position.y:
			lowest = leg
	if furthest.tooFar():
		furthest.step(furthest.origin+body.global_position+v)
	body.global_position.y = lerp(body.global_position.y, lowest.global_position.y-lowest.legLength*0.2, min(10.0*delta, 1.0))
	pass
