extends Node3D

var time := 0.0
@export var legs:Array[Node3D]
@export var arms:Array[Node3D]
@export var stepHeight = 0.5
@export var legLength = 1.0
var legStartPositions:Array[Vector3]
var armStartPositions:Array[Vector3]
var startPosition:Vector3
var speed = 0.1
var walkRadius = 10.0

func castRay(pos1:Vector3, pos2:Vector3) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(pos1, pos2)
	return space_state.intersect_ray(query)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	startPosition = position
	for leg in legs:
		legStartPositions.append(leg.global_position)
	for arm in arms:
		armStartPositions.append(arm.position)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta*speed
	var sum := Vector2(0.0, 0.0)
	var lowest = legs[0].global_position.y
	var dist2 = 0.0
	for leg in legs:
		var pos = leg.global_position
		var result = castRay(Vector3(pos.x, pos.y+legLength, pos.z), Vector3(pos.x, pos.y-legLength, pos.z))
		if result:
			pos.y = result.position.y
		leg.global_position.y = lerp(leg.global_position.y, pos.y, min(10.0*delta, 1.0))
		if (leg.global_position-(global_position+Vector3(0.0, legLength, 0.0))).length() > dist2:
			dist2 = (leg.global_position-(global_position+Vector3(0.0, legLength, 0.0))).length()
		sum += Vector2(leg.global_position.x, leg.global_position.z)
		if lowest > leg.global_position.y:
			lowest = leg.global_position.y
	global_position.y = lerp(position.y, lowest-legLength*0.2, min(5.0*delta, 1.0))
	var center:Vector2 = sum/legs.size()
	var radius:float = (Vector2(legs[0].position.x, legs[0].position.z)-center).length()*2.0
	var dist = (Vector2(global_position.x, global_position.z)-center).length()
	if(dist > radius || dist2 > legLength*1.1):
		var furthestLeg := legs[0]
		var furthestLegIndex := 0
		for i in range(legs.size()):
			var leg = legs[i]
			if (leg.global_position-global_position).length() > (furthestLeg.global_position-global_position).length():
				furthestLeg = leg
				furthestLegIndex = i
		var pos = legStartPositions[furthestLegIndex]+global_position
		pos.y += stepHeight
		var v = speed*walkRadius*delta*40.0
		pos.x += cos(time+PI/2.0)*v
		pos.z += sin(time+PI/2.0)*v
		furthestLeg.global_position = pos
	position.x = cos(time)*walkRadius
	position.z = sin(time)*walkRadius
	pass
