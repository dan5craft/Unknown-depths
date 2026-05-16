class_name Leg extends Node3D

@export var legLength = 1.0
@export var legStepHeight = 0.2
@export var legMass = 5.0
@export var maxLegForce = 588.0
@export var body:Node3D
@export var bodyController:bodyController
@export var maxStepTime:float = 0.5
var stepTime:float = 2.0
@export var isSymmetrical:bool = false
@export var symmetricalEqual:Leg

var targetPos:Vector3
var targetSpeed:Vector3
var maxSpeed:Vector3 = Vector3(0.1, 0.1, 0.1)
var stepping := false
var grounded := true
var moveTo := true
var brakeToGround := false
var origin:Vector3
var stepOrigin:Vector3
var stepOriginTime:float
var velocity:Vector3 = Vector3(0.0, 0.0, 0.0)
var force:Vector3 = Vector3(0.0, 0.0, 0.0)
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

func dist() -> float:
	var root = bodyController.newPos+origin.rotated(Vector3.UP, bodyController.phi)
	root.y = bodyController.newPos.y+legLength
	var Dist = (root-newPos).length()
	return Dist

func dist2D() -> Vector2:
	var root = bodyController.newPos+origin.rotated(Vector3.UP, bodyController.phi)
	root.y = bodyController.newPos.y+legLength
	var Dist = root-newPos
	return Vector2(Dist.x, Dist.z)

func tooFar() -> bool:
	var Dist = dist()
	if Dist > legLength:
		return true
	else:
		return false

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

func calcForce() -> Vector3:
	var distance = targetPos-newPos
	var forceNormalized = distance.normalized()
	var mass = legMass
	var vel = velocity
	var forceReq = -Globals.gravity*mass
	var targetAtGround = false
	var start = targetPos
	var end = targetPos
	start.y += 0.1
	end.y -= 0.1
	var result = castRay(start, end)
	if result:
		if result.position.y >= targetPos.y-0.05:
			targetAtGround = true
	if distance.y < 0.0:
		forceReq = 0.0
	forceNormalized.y = min(1.0, forceReq/maxLegForce)
	var root = bodyController.newPos+origin.rotated(Vector3.UP, bodyController.phi)
	var Dist = root-newPos
	var standingOffset = legLength*(1.0-bodyController.standingPercent)+legLength*bodyController.standingPercent-sqrt(pow(legLength*bodyController.standingPercent, 2.0)-(pow(Dist.x, 2.0)+pow(Dist.z, 2.0)))
	if grounded and targetPos.y <= newPos.y+0.05 or grounded and newPos.y-bodyController.newPos.y-standingOffset >= 0.05:
		mass = bodyController.mass/bodyController.getGroundedLegCount()
		vel.y = bodyController.velocity.y
		distance.y = targetPos.y-bodyController.newPos.y-standingOffset
		forceReq = Globals.gravity*mass
		if distance.y < 0.0:
			forceReq = 0.0
		forceNormalized.y = min(1.0, getMagnitude(forceReq)/maxLegForce)*getSign(forceReq)
	var forceLeft = sqrt(1.0-pow(forceNormalized.y, 2.0))
	if getMagnitude(forceNormalized.y) > 0.0:
		var upwardsForce = min(forceLeft/3, distance.y)
		forceNormalized.y = min(1.0, getMagnitude(forceNormalized.y)+upwardsForce)*getSign(forceNormalized.y)
	$MeshInstance3D.get_surface_override_material(0).albedo_color = Color(0.0, 1.0, 0.0)
	if getSign(vel.y) == getSign(distance.y) and distance.y != 0.0:
		var brakeAY = pow(targetSpeed.y, 2.0)-pow(vel.y, 2.0)/(2.0*distance.y)-Globals.gravity
		if grounded:
			brakeAY *= -1.0
		var brakeForceY = brakeAY*mass
		if getMagnitude(brakeForceY) > maxLegForce or distance.y > 0.0 and brakeAY > -1.0 and grounded or getMagnitude(distance.y) < 0.1:
			$MeshInstance3D.get_surface_override_material(0).albedo_color = Color(1.0, 0.0, 0.0)
			if grounded or not targetAtGround or brakeToGround:
				forceNormalized.y = min(1.0, getMagnitude(brakeForceY)/maxLegForce)*getSign(brakeForceY)
				if grounded:
					forceNormalized.y = min(0.0, forceNormalized.y)
	if forceNormalized.x != 0.0 or forceNormalized.z != 0.0:
		forceLeft = sqrt(1.0-pow(forceNormalized.y, 2.0))
		var sumXZ = getMagnitude(forceNormalized.x)+getMagnitude(forceNormalized.z)
		if grounded and moveTo:
			vel.x = bodyController.velocity.x
			vel.z = bodyController.velocity.z
			root = bodyController.newPos+origin.rotated(Vector3.UP, bodyController.phi)
			distance.x = newPos.x-root.x
			distance.z = newPos.z-root.z
			var distSum = getMagnitude(distance.x)+getMagnitude(distance.z)
			if distSum > 0.001:
				var weightX = getMagnitude(distance.x)/distSum*getSign(distance.x)
				var weightZ = getMagnitude(distance.z)/distSum*getSign(distance.z)
				forceNormalized.x = -weightX*forceLeft
				forceNormalized.z = -weightZ*forceLeft
		elif grounded and not moveTo:
			forceNormalized.x = 0.0
			forceNormalized.z = 0.0
		elif sumXZ > 0.001:
			var weightX = getMagnitude(forceNormalized.x)/sumXZ*getSign(forceNormalized.x)
			var weightZ = getMagnitude(forceNormalized.z)/sumXZ*getSign(forceNormalized.z)
			forceNormalized.x = weightX*forceLeft
			forceNormalized.z = weightZ*forceLeft
	forceNormalized.x = min(getMagnitude(distance.x), getMagnitude(forceNormalized.x))*getSign(forceNormalized.x)
	forceNormalized.z = min(getMagnitude(distance.z), getMagnitude(forceNormalized.z))*getSign(forceNormalized.z)
	if getSign(vel.x) == getSign(distance.x) and distance.x != 0.0:
		var brakeAX = pow(targetSpeed.x, 2.0)-pow(vel.x, 2.0)/(2.0*distance.x)
		var brakeForceX = brakeAX*mass
		if getMagnitude(brakeForceX)/maxLegForce > getMagnitude(forceNormalized.x)-0.1:
			if grounded:
				brakeForceX *= -1.0
			elif grounded and not moveTo:
				brakeForceX = 0.0
			$MeshInstance3D.get_surface_override_material(0).albedo_color = Color(1.0, 0.0, 0.0)
			forceNormalized.x = min(1.0, getMagnitude(brakeForceX)/maxLegForce)*getSign(brakeForceX)
	if getSign(vel.z) == getSign(distance.z) and distance.z != 0.0:
		var brakeAZ = pow(targetSpeed.z, 2.0)-pow(vel.z, 2.0)/(2.0*distance.z)
		var brakeForceZ = brakeAZ*mass
		if getMagnitude(brakeForceZ)/maxLegForce > getMagnitude(forceNormalized.z)-0.1:
			if grounded:
				brakeForceZ *= -1.0
			elif grounded and not moveTo:
				brakeForceZ = 0.0
			$MeshInstance3D.get_surface_override_material(0).albedo_color = Color(1.0, 0.0, 0.0)
			forceNormalized.z = min(1.0, getMagnitude(brakeForceZ)/maxLegForce)*getSign(brakeForceZ)
	return forceNormalized*maxLegForce

func move():
	var timeStep = 1.0/bodyController.simFPS
	oldPos = newPos
	force = calcForce()
	var appliedForce:Vector3 = force+Vector3(0.0, Globals.gravity*legMass, 0.0)
	if newPos.y-bodyController.newPos.y > legLength*0.8:
		if grounded:
			bodyController.velocity.y = max(bodyController.velocity.y, 0.0)
		velocity.y = bodyController.velocity.y
		newPos.y = bodyController.newPos.y+legLength*0.8
	var a:Vector3 = appliedForce/legMass
	velocity += a*timeStep
	newPos += velocity*timeStep
	var root = bodyController.newPos+origin.rotated(Vector3.UP, bodyController.phi)
	root.y = bodyController.newPos.y+legLength
	var Dist = (root-newPos)
	if Dist.length() > legLength:
		var diff = root-Dist*legLength/Dist.length()
		newPos = diff
	var start = oldPos
	var end = newPos
	start.y += 0.1
	end.y -= 0.1
	var result = castRay(start, end)
	if result:
		if result.position.y >= newPos.y:
			grounded = true
			newPos.y = result.position.y
			bodyController.velocity += -(appliedForce-Vector3(0.0, Globals.gravity*legMass, 0.0))/(bodyController.mass)*timeStep
			velocity = Vector3(0.0, 0.0, 0.0)
		else:
			grounded = false
	else:
		grounded = false

func setTarget(pos:Vector3, speed:Vector3):
	targetPos = pos
	targetSpeed = speed
func step(pos:Vector3, speed:Vector3):
	stepping = true
	setTarget(pos, speed)
