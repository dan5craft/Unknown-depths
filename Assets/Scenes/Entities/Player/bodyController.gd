class_name bodyController extends Node3D

@export_category("Body Controller")
@export var legs:Array[Leg]
@export var body:Node3D
@export var mass:float = 80.0
@export var simFPS:int = 30
@export var smoothFPS:bool = true
@export var timeScale = 1.0
@export var bodyHeight = 1.9
var velocity:Vector3 = Vector3(0.0, 0.0, 0.0)
@export_enum("Standing", "Walking", "Falling") var state:String = "Standing"
@export_category("Legs")
@export var standingPercent = 1.0
@export var stepLength:float = 0.4
@export_category("Movement")
@export var moveDirection:Vector3 = Vector3(0.0, 0.0, 1.0)
@export var movementSpeed = 1.0
@export var maxMovementSpeed = 5.0
@export var movementAcceleration = 5.0
@export var maxGroundDistance = 0.5
var phi = PI/2.0

var oldPos:Vector3 = Vector3(0.0, 0.0, 0.0)
var newPos:Vector3 = Vector3(0.0, 0.0, 0.0)
var timer:float = -3.0
var timeStep


func castRay(pos1:Vector3, pos2:Vector3) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(pos1, pos2)
	return space_state.intersect_ray(query)

func getLegCount() -> int:
	return legs.size()

func getGroundedLegCount() -> int:
	var sum:int = 0
	for leg in legs:
		if leg.grounded and not leg.stepping:
			sum+=1
	return sum

func getLowestLeg() -> Leg:
	var lowest:Leg = legs[0]
	for leg in legs:
		if leg.newPos.y < lowest.newPos.y:
			lowest = leg
	return lowest

func getHighestLeg() -> Leg:
	var highest:Leg = legs[0]
	for leg in legs:
		if leg.newPos.y > highest.newPos.y:
			highest = leg
	return highest

func getHorizontallyFurthestLeg() -> Leg:
	var furthest:Leg = legs[0]
	var furthestDistance = furthest.getDistanceHorizontal()
	for leg in legs:
		var distance = leg.getDistanceHorizontal()
		if distance > furthestDistance:
			furthest = leg
			furthestDistance = distance
	return furthest

func getFurthestLeg() -> Leg:
	var furthest:Leg = legs[0]
	var furthestDistance = furthest.getDistance()
	for leg in legs:
		var distance = leg.getDistance()
		if distance > furthestDistance:
			furthest = leg
			furthestDistance = distance
	return furthest

func getTargetHeight() -> float:
	var lowest:Leg = getLowestLeg()
	var targetHeight:float = lowest.newPos.y-lowest.legLength*(1.0-standingPercent)
	var furthest:Leg = getHorizontallyFurthestLeg()
	var b = furthest.getDistanceHorizontal()
	var a = sqrt(pow(furthest.legLength, 2.0)-pow(b, 2.0))
	var offset = furthest.legLength-a
	var targetHeight2 = furthest.newPos.y-offset-furthest.legLength*(1.0-standingPercent)
	if targetHeight2 < targetHeight:
		targetHeight = targetHeight2
	#newPos.y = lerp(newPos.y, targetHeight, min(5.0*timeStep, 1.0))
	#newPos.y = targetHeight
	return targetHeight

func fallingCondition() -> bool:
	var start:Vector3 = newPos+Vector3.UP*bodyHeight
	var end:Vector3 = newPos+Vector3.DOWN*maxGroundDistance
	var result = castRay(start, end)
	if result:
		return false
	else:
		return true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	oldPos = body.global_position
	newPos = body.global_position
	timeStep = 1.0/simFPS
	pass # Replace with function body.

func enterStanding() -> void:
	state = "Standing"

func standing() -> void:
	if fallingCondition():
		enterFalling()
		return
	newPos.y = lerp(newPos.y, getTargetHeight(), min(5.0*timeStep, 1.0))
	if velocity.length() > 0.0:
		var dir = -velocity.normalized()
		var a = dir*movementAcceleration*timeStep
		if velocity.x < 0.0:
			velocity.x = min(velocity.x+a.x, 0.0)
		elif velocity.x > 0.0:
			velocity.x = max(velocity.x+a.x, 0.0)
		if velocity.z < 0.0:
			velocity.z = min(velocity.z+a.z, 0.0)
		elif velocity.z > 0.0:
			velocity.z = max(velocity.z+a.z, 0.0)
	for leg in legs:
		if not leg.stepping:
			var target = leg.getStepTarget(0.0, 0.0)
			if target and (target-leg.newPos).length() > 0.1:
				if leg.isSymmetrical and not leg.symmetricalEqual.stepping or not leg.isSymmetrical:
					leg.step(0.0, 0.0)
		else:
			leg.setStepTarget(0.0, 0.0)
		leg.legAcceleration = max(velocity.length()*20.0, 10.0)
		leg.stepHeight = leg.maxStepHeight*min(velocity.length()/maxMovementSpeed, 1.0)
		leg.move()

func enterWalking() -> void:
	state = "Walking"
	#legs[0].step(legs[0].origin.rotated(Vector3.UP, phi)+newPos+moveDirection*stepLength, 0.5)
	#legs[0].step(0.0, legs[0].maxAngle)

func getRealMoveDirection():
	return moveDirection.rotated(Vector3.UP, phi)

func walking():
	var moveDir = getRealMoveDirection()
	if fallingCondition():
		enterFalling()
		return
	newPos.y = lerp(newPos.y, getTargetHeight(), min(5.0*timeStep, 1.0))
	var maxVel = moveDir*movementSpeed
	var dir = (maxVel-velocity).abs().normalized()
	#if moveDir.x < 0.01:
		#if velocity.x > 0.0 or velocity.x < 0.0:
			#dir.x = 1.0
	#if moveDir.z == 0.0:
		#if velocity.z > 0.0 or velocity.z < 0.0:
			#dir.z = 1.0
	#dir = dir.normalized()
	var a = dir*movementAcceleration*timeStep
	if velocity.x < maxVel.x:
		velocity.x = min(velocity.x+a.x, maxVel.x)
	elif velocity.x > maxVel.x:
		velocity.x = max(velocity.x-a.x, maxVel.x)
	if velocity.z < maxVel.z:
		velocity.z = min(velocity.z+a.z, maxVel.z)
	elif velocity.z > maxVel.z:
		velocity.z = max(velocity.z-a.z, maxVel.z)
	if moveDir.length() == 0.0 and velocity.length() < 0.1:
		enterStanding()
		return
	var biggestAngle := 0.0
	var biggestAngleLeg:Leg = null
	var moveAngle = rad_to_deg(atan(velocity.x/velocity.z))
	if velocity.z == 0.0:
		moveAngle = 90*sign(velocity.x)
	if velocity.z < 0.0:
		moveAngle += 180
	elif velocity.x < 0.0:
		moveAngle += 360
	for leg in legs:
		var maxAngle = min(leg.maxAngle*velocity.length()/maxMovementSpeed, leg.maxAngle)
		#print("Move Angle: "+str(moveAngle)+" Max Angle: "+str(maxAngle))
		if not leg.stepping:
			var root = leg.origin.rotated(Vector3.UP, phi)+newPos
			root.y = newPos.y+leg.legLength
			var Dist = leg.newPos - root
			var angle = rad_to_deg(atan(sqrt(pow(Dist.x, 2.0)+pow(Dist.z, 2.0))/-Dist.y))
			if Dist.dot(velocity) > 0.0:
				angle *= -1.0
			var target = leg.getStepTarget(moveAngle, maxAngle)
			if angle > maxAngle and angle > biggestAngle:
				biggestAngle = angle
				biggestAngleLeg = leg
			if target and abs(target.y-leg.newPos.y) > 0.1:
				if leg.isSymmetrical and not leg.symmetricalEqual.stepping or not leg.isSymmetrical:
					leg.step(moveAngle, maxAngle)
		else:
			leg.setStepTarget(moveAngle, maxAngle)
		leg.legAcceleration = max(velocity.length()*20.0, 10.0)
		leg.stepHeight = leg.maxStepHeight*min(velocity.length()/maxMovementSpeed, 1.0)
		leg.move()
	if biggestAngleLeg != null:
		if biggestAngleLeg.isSymmetrical and not biggestAngleLeg.symmetricalEqual.stepping or not biggestAngleLeg.isSymmetrical:
			var maxAngle = min(biggestAngleLeg.maxAngle*velocity.length()/maxMovementSpeed, biggestAngleLeg.maxAngle)
			biggestAngleLeg.step(moveAngle, maxAngle)
	pass

func enterFalling():
	state = "Falling"
	for leg in legs:
		leg.setTarget(newPos+leg.origin)
		leg.legAcceleration = max(velocity.length()*20.0, 10.0)
		leg.move()

func falling():
	velocity.y += Globals.gravity*timeStep
	for leg in legs:
		leg.setTarget(newPos+leg.origin)
		leg.legAcceleration = max(velocity.length()*20.0, 10.0)
		leg.move()
		var result = castRay(leg.oldPos, leg.newPos)
		if result:
			leg.newPos = result.position
			velocity.y = 0.0
			if newPos.y < leg.newPos.y-leg.legLength*0.8:
				newPos.y = leg.newPos.y-leg.legLength*0.8
			enterStanding()
			#print("Hit ground!")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	body.basis = body.basis.slerp(Basis.IDENTITY.rotated(Vector3.UP, phi), min(15.0*delta, 1.0))
	for leg in legs:
		leg.basis = leg.basis.slerp(Basis.IDENTITY.rotated(Vector3.RIGHT, deg_to_rad(106.3)).rotated(Vector3.UP, phi), min(15.0*delta, 1.0))
	while timer > timeStep/timeScale:
		timer -= timeStep/timeScale
		for leg in legs:
			leg.timer += timeStep
		oldPos = newPos
		newPos += velocity*timeStep
		#print(state)
		if state == "Standing":
			standing()
		if state == "Walking":
			walking()
		if state == "Falling":
			falling()
		body.global_position = newPos
		for leg in legs:
			if leg.newPos.y - newPos.y > leg.legLength*0.8:
				leg.newPos.y = newPos.y + leg.legLength*0.8
			leg.global_position = leg.newPos
	if smoothFPS:
		var timePercent = timer/(timeStep/timeScale)
		body.global_position = lerp(oldPos, newPos, timePercent)
		for leg in legs:
			leg.global_position = lerp(leg.oldPos, leg.newPos, timePercent)
