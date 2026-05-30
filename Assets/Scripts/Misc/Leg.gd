class_name Leg extends Node3D

@export var legLength = 1.0
@export var stepHeight = 0.3
@export var body:Node3D
@export var bodyControl:bodyController
@export var maxAngle:float = 20.0
@export var isSymmetrical:bool = false
@export var symmetricalEqual:Leg
@export var legAcceleration:float = 5.0
@export var legMinStepSpeed:float = 0.1
var timer:float
var velocity:Vector3 = Vector3.ZERO

var targetPos:Vector3
var stepping := false
var grounded := true
var origin:Vector3
var stepOrigin:Vector3
var stepOriginTime:float
var oldPos:Vector3 = Vector3(0.0, 0.0, 0.0)
var newPos:Vector3 = Vector3(0.0, 0.0, 0.0)

func _ready() -> void:
	var pos = Vector3(body.global_position.x+position.x, body.global_position.y+position.y, body.global_position.z+position.z)
	global_position = pos
	oldPos = pos
	newPos = pos
	targetPos = pos
	origin = pos-body.global_position

func castRay(pos1:Vector3, pos2:Vector3) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(pos1, pos2)
	return space_state.intersect_ray(query)

#func stepFunction(x:float, p1:Vector2, p2:Vector2, p3:Vector2) -> float:
	#var part1:float = (x-p2.x)*(x-p3.x)/((p1.x-p2.x)*(p1.x-p3.x))*p1.y
	#var part2:float = (x-p1.x)*(x-p3.x)/((p2.x-p1.x)*(p2.x-p3.x))*p2.y
	#var part3:float = (x-p1.x)*(x-p2.x)/((p3.x-p1.x)*(p3.x-p2.x))*p3.y
	#return part1+part2+part3

func getSign(val:float) -> float:
	if val < 0.0:
		return -1.0
	else:
		return 1.0

func getMagnitude(val:float) -> float:
	return sqrt(pow(val, 2.0))

func sigmoid(t:float, time:float, h:float):
	var val = h
	if t < time:
		var e = 2.71828182846
		var x = t/time
		val = pow(1.0+pow(e, (-2.0*x+1.0)/(x-pow(x, 2.0))), -1.0)*h
	return val

func calcBreakAcceleration(distance:float, currentSpeed:float, targetedSpeed:float, targetsSpeed:float, constantAcceleration:float):
	var v = (pow(targetedSpeed, 2.0)-pow(currentSpeed, 2.0) - 2*targetsSpeed*(targetedSpeed-currentSpeed)) / (2*distance) - constantAcceleration
	#print("d: "+str(distance)+" v: "+str(currentSpeed)+" i: "+str(targetedSpeed)+" k: "+str(targetsSpeed)+" g: "+str(constantAcceleration)+"\na: "+str(v))
	return v

func calcAcceleration():
	var start:Vector3 = newPos
	var end:Vector3 = newPos+Vector3.DOWN*stepHeight
	var result:Dictionary = castRay(start, end)
	var horizontalDistance:Vector2 = Vector2(targetPos.x-newPos.x, targetPos.z-newPos.z)
	var targetHeight:float = targetPos.y + min(stepHeight, horizontalDistance.length())
	if result:
		targetHeight = result.position.y + min(stepHeight, horizontalDistance.length())
	var verticalDistance:float = targetHeight - newPos.y
	#var yAcceleration:float = min(legAcceleration*2.0, abs(verticalDistance))*sign(verticalDistance)
	var yAcceleration:float = legAcceleration*2.0*sign(verticalDistance)
	if abs(verticalDistance) > 0.0 and sign(velocity.y) == sign(verticalDistance):
		var breakAcceleration = calcBreakAcceleration(verticalDistance, velocity.y, 0.0, 0.0, 0.0)
		if abs(breakAcceleration) >= legAcceleration*2.0 or abs(verticalDistance) < 0.1:
			yAcceleration = min(abs(breakAcceleration), legAcceleration*2.0)*sign(breakAcceleration)
	var horizontalAcceleration:Vector2
	#horizontalAcceleration.x = min(legAcceleration, abs(horizontalDistance.x))*sign(horizontalDistance.x)
	#horizontalAcceleration.y = min(legAcceleration, abs(horizontalDistance.y))*sign(horizontalDistance.y)
	horizontalAcceleration.x = legAcceleration*sign(horizontalDistance.x)
	horizontalAcceleration.y = legAcceleration*sign(horizontalDistance.y)
	if abs(horizontalDistance.x) > 0.0 and sign(velocity.x) == sign(horizontalDistance.x):
		var breakAcceleration = calcBreakAcceleration(horizontalDistance.x, velocity.x, 0.0, 0.0, 0.0)
		if abs(breakAcceleration) >= legAcceleration or abs(horizontalDistance.x) < 0.1:
			horizontalAcceleration.x = min(abs(breakAcceleration), legAcceleration)*sign(breakAcceleration)
	if abs(horizontalDistance.y) > 0.0 and sign(velocity.z) == sign(horizontalDistance.y):
		var breakAcceleration = calcBreakAcceleration(horizontalDistance.y, velocity.z, 0.0, 0.0, 0.0)
		if abs(breakAcceleration) >= legAcceleration or abs(horizontalDistance.y) < 0.1:
			horizontalAcceleration.y = min(abs(breakAcceleration), legAcceleration)*sign(breakAcceleration)
	print(horizontalDistance)
	print(newPos.y)
	print(velocity.y)
	return Vector3(horizontalAcceleration.x, yAcceleration, horizontalAcceleration.y)

#func stepFunction(t:float) -> float:
	#var val = targetPos.y-stepOrigin.y
	#if t < stepTime:
		#var offset = sigmoid(t, stepTime, targetPos.y-stepOrigin.y)
		#val = sin(t*2.0*PI/stepTime-PI/2.0)*stepHeight/2.0+stepHeight/2.0 + offset
	#return val

func move():
	oldPos = newPos
	var timeStep = 1.0/bodyControl.simFPS
	var a:Vector3 = calcAcceleration()
	velocity += a*timeStep
	newPos += velocity*timeStep
	var travelDist = newPos-oldPos
	var targetDist = targetPos-newPos
	if sign(travelDist.y) != sign(targetDist.y) and sign(travelDist.y) == -1.0:
		newPos.y = targetPos.y
	if sign(travelDist.x) != sign(targetDist.x):
		newPos.x = targetPos.x
	if sign(travelDist.z) != sign(targetDist.z):
		newPos.z = targetPos.z
	if (targetPos-newPos).length() < 0.05:
		newPos = targetPos
		velocity = Vector3.ZERO
func step(pos:Vector3, time:float):
	stepping = true
	stepOrigin = newPos
	stepOriginTime = timer
	#var positions = []
	var start = pos + Vector3.UP*legLength
	var end = pos + Vector3.DOWN*legLength/2.0
	var result = castRay(start, end)
	if result:
		grounded = true
		pos.y = result.position.y
	else:
		grounded = false
	targetPos = pos
