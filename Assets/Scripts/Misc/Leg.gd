class_name Leg extends Node3D

@export var legLength = 1.0
@export var stepHeight = 0.2
@export var body:Node3D
@export var bodyControl:bodyController
@export var maxAngle:float = 30.0
@export var isSymmetrical:bool = false
@export var symmetricalEqual:Leg
@export var legAcceleration:float = 20.0
@export var legMinStepSpeed:float = 0.1
@export var debug:bool = false
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

func getDistanceHorizontal() -> float:
	var root:Vector3 = bodyControl.newPos+origin.rotated(Vector3.UP, bodyControl.phi)
	var distance:float = sqrt(pow(newPos.x-root.x, 2.0)+pow(newPos.z-root.z, 2.0))
	return distance

func getDistance() -> float:
	var root:Vector3 = bodyControl.newPos+origin.rotated(Vector3.UP, bodyControl.phi)
	root.y = root.y+legLength
	var distance:float = sqrt(pow(newPos.x-root.x, 2.0)+pow(newPos.y-root.y, 2.0)+pow(newPos.z-root.z, 2.0))
	return distance

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
	var horizontalDistance:Vector2 = Vector2(targetPos.x-newPos.x, targetPos.z-newPos.z)
	var targetHeight:float = targetPos.y
	if stepping and horizontalDistance.length() > bodyControl.velocity.length()/4.0:
		var result:Dictionary = castRay(start, end)
		if result and newPos.y > targetPos.y:
			targetHeight = result.position.y + min(stepHeight, horizontalDistance.length())
		else:
			targetHeight += min(stepHeight, horizontalDistance.length())
	var verticalDistance:float = targetHeight - newPos.y
	#var yAcceleration:float = min(legAcceleration*2.0, abs(verticalDistance))*sign(verticalDistance)
	var yAcceleration:float = legAcceleration*2.0*sign(verticalDistance)
	if abs(verticalDistance) > 0.0 and sign(velocity.y) == sign(verticalDistance):
		var breakAcceleration = calcBreakAcceleration(verticalDistance, velocity.y, 0.0, 0.0, 0.0)
		if abs(breakAcceleration) >= legAcceleration*2.0 or abs(velocity.y) > 0.1 and abs(verticalDistance) < 0.1:
			yAcceleration = min(abs(breakAcceleration), legAcceleration*2.0)*sign(breakAcceleration)
	var horizontalAcceleration:Vector2
	#horizontalAcceleration.x = min(legAcceleration, abs(horizontalDistance.x))*sign(horizontalDistance.x)
	#horizontalAcceleration.y = min(legAcceleration, abs(horizontalDistance.y))*sign(horizontalDistance.y)
	horizontalAcceleration = horizontalDistance.normalized()*legAcceleration
	if abs(horizontalDistance.x) > 0.0 and sign(velocity.x) == sign(horizontalDistance.x):
		var breakAcceleration = calcBreakAcceleration(horizontalDistance.x, velocity.x, bodyControl.velocity.x*1.5, bodyControl.velocity.x*1.5, 0.0)
		if abs(breakAcceleration) >= legAcceleration or abs(velocity.x) > 0.1 and abs(horizontalDistance.x) < 0.1:
			horizontalAcceleration.x = min(abs(breakAcceleration), legAcceleration)*sign(breakAcceleration)
	if abs(horizontalDistance.y) > 0.0 and sign(velocity.z) == sign(horizontalDistance.y):
		var breakAcceleration = calcBreakAcceleration(horizontalDistance.y, velocity.z, bodyControl.velocity.z*1.5, bodyControl.velocity.z*1.5, 0.0)
		if abs(breakAcceleration) >= legAcceleration or abs(velocity.z) > 0.1 and abs(horizontalDistance.y) < 0.1:
			horizontalAcceleration.y = min(abs(breakAcceleration), legAcceleration)*sign(breakAcceleration)
	return Vector3(horizontalAcceleration.x, yAcceleration, horizontalAcceleration.y)

#func stepFunction(t:float) -> float:
	#var val = targetPos.y-stepOrigin.y
	#if t < stepTime:
		#var offset = sigmoid(t, stepTime, targetPos.y-stepOrigin.y)
		#val = sin(t*2.0*PI/stepTime-PI/2.0)*stepHeight/2.0+stepHeight/2.0 + offset
	#return val

func move():
	if debug:
		$MeshInstance3D.visible = true
		$MeshInstance3D2.global_position = targetPos
		if stepping:
			$MeshInstance3D2.visible = true
		else:
			$MeshInstance3D2.visible = false
	else:
		$MeshInstance3D.visible = false
		$MeshInstance3D2.visible = false
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
		stepping = false
		velocity = Vector3.ZERO

func getStepTarget(directionalAngle:float, stepAngle:float):
	directionalAngle = directionalAngle*PI/180 + bodyControl.phi
	stepAngle *= PI/180
	var root = bodyControl.newPos+origin.rotated(Vector3.UP, bodyControl.phi)
	root.y = root.y + legLength
	var angle = stepAngle
	while true:
		var start = root
		var end = Vector3.ZERO
		end.x = sin(directionalAngle)*legLength*1.5
		end.z = cos(directionalAngle)*legLength*1.5
		var rotationAxis = Vector3(sin(directionalAngle+PI/2.0), 0.0, cos(directionalAngle+PI/2.0))
		end = end.rotated(rotationAxis, PI/2.0-angle)+root
		var result = castRay(start, end)
		if result:
			var distance = sqrt(pow(result.position.x-root.x, 2.0)+pow(result.position.z-root.z, 2.0))
			if distance > legLength:
				angle -= PI*0.01
				if angle < 0.0:
					return false
				continue
			return result.position
		else:
			angle -= PI*0.01
			#print(angle)
			if angle < 0.0:
				return false

func setStepTarget(directionalAngle:float, stepAngle:float) -> bool:
	var target = getStepTarget(directionalAngle, stepAngle)
	if target:
		targetPos = target
		return true
	else:
		return false

func setTarget(pos:Vector3):
	targetPos = pos
	if stepping:
		stepping = false

func step(directionalAngle:float, stepAngle:float):
	if stepping:
		print("Leg is already stepping dumbass! >:(")
		return
	var foundTarget = setStepTarget(directionalAngle, stepAngle)
	if foundTarget:
		stepping = true
