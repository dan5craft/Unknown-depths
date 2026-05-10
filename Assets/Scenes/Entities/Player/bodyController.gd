extends Node3D

var time := 0.0
@export var legs:Array[Leg]
@export var armMarkers:Array[Node3D]
@export var body:Node3D
@export var balanceRadius = 0.1
@export var standingPercent = 0.9
var speed = 0.1
var walkRadius = 10.0
var lastPos:Vector2
var lastPosTime:int

func castRay(pos1:Vector3, pos2:Vector3) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(pos1, pos2)
	return space_state.intersect_ray(query)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lastPosTime = Time.get_ticks_msec()
	lastPos = Vector2(body.global_position.x, body.global_position.z)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta*speed
	var currentPosTime = Time.get_ticks_msec()
	var diffPosTime:float = float(currentPosTime-lastPosTime)/1000.0
	lastPosTime = Time.get_ticks_msec()
	var v:Vector2 = (Vector2(body.global_position.x, body.global_position.z)-lastPos)/diffPosTime
	lastPos = Vector2(body.global_position.x, body.global_position.z)
	body.global_position.x = cos(time)*walkRadius
	body.global_position.z = sin(time)*walkRadius
	var lowest:Leg
	var furthest:Leg
	for leg in legs:
		if not leg.stepping:
			lowest = leg
			furthest = leg
			break
	var balanced = false
	for leg in legs:
		if leg.stepping:
			continue
		var dist1 = leg.dist2D()+Vector2(leg.legLength/2.0/v.x, leg.legLength/2.0/v.y)
		var dist2 = furthest.dist2D()+Vector2(furthest.legLength/2.0/v.x, furthest.legLength/2.0/v.y)
		if dist1.length() > dist2.length():
			furthest = leg
		if leg.global_position.y < lowest.global_position.y:
			lowest = leg
		var dist = (body.global_position-leg.global_position).length()
		if dist <= balanceRadius:
			balanced = true
	if furthest.tooFar() or not balanced:
		var mult := Vector2(v.x/v.length(), v.y/v.length())
		if v.length() == 0.0:
			mult = Vector2(0.0, 0.0)
		else:
			furthest.stepTime = furthest.legLength/2.0/v.length()
		var speedOffset := Vector3(v.x*furthest.stepTime+mult.x*furthest.legLength/2.0*standingPercent, 0.0, v.y*furthest.stepTime+mult.y*furthest.legLength/2.0*standingPercent)
		var pos := furthest.origin+body.global_position+speedOffset
		var start := Vector3(pos.x, pos.y+furthest.legLength*2.0, pos.z)
		var end := Vector3(pos.x, pos.y-furthest.legLength*2.0, pos.z)
		var result = castRay(start, end)
		if result:
			pos.y = result.position.y
		furthest.step(pos)
		#furthest.step(furthest.origin+body.global_position+Vector3(v.x*furthest.stepTime, 0.0, v.y*furthest.stepTime))
	for leg in legs:
		leg.move()
	body.global_position.y = lerp(body.global_position.y, lowest.global_position.y-lowest.legLength*(1.0-standingPercent), min(5.0*delta, 1.0))
	#body.global_position.y = lowest.global_position.y-lowest.legLength*0.2
	pass
