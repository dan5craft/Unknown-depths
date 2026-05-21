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
var bodyTargetPos:Vector3 = Vector3(0.0, -0.2, 0.0)
var maxHorizontalSpeed:Vector2 = Vector2(100.0, 100.0)
var stepping := false
var lifting := false
var grounded := true
var moveTo := false
var brakeToGround := false
var targetBodySpeed := true
var jumping := false
var jumpSpeed:float = 1.0
var origin:Vector3
var stepOrigin:Vector3
var stepOriginTime:float
var velocity:Vector3 = Vector3(0.0, 0.0, 0.0)
var force:Vector3 = Vector3(0.0, 0.0, 0.0)
var oldPos:Vector3 = Vector3(0.0, 0.0, 0.0)
var newPos:Vector3 = Vector3(0.0, 0.0, 0.0)
var effectiveMass:float
var appliedMass:float

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

func bodyAtTargetSpeed(margin:float = 0.05) -> bool:
	var BOOL = true
	if bodyController.velocity.x > bodyController.targetSpeed.x+margin or  bodyController.velocity.x < bodyController.targetSpeed.x-margin:
		BOOL = false
	if bodyController.velocity.z > bodyController.targetSpeed.y+margin or  bodyController.velocity.z < bodyController.targetSpeed.y-margin:
		BOOL = false
	return BOOL

func jump(speed:float):
	jumping = true
	jumpSpeed = speed

func calcBreakAcceleration(distance:float, currentSpeed:float, targetedSpeed:float, targetsSpeed:float, constantAcceleration:float):
	var v = (pow(targetedSpeed, 2.0)-pow(currentSpeed, 2.0) - 2*targetsSpeed*(targetedSpeed-currentSpeed)) / (2*distance) - constantAcceleration
	#print("d: "+str(distance)+" v: "+str(currentSpeed)+" i: "+str(targetedSpeed)+" k: "+str(targetsSpeed)+" g: "+str(constantAcceleration)+"\na: "+str(v))
	return v

func distFromStandPos():
	return newPos.y-bodyController.newPos.y-legLength*(1.0-bodyController.standingPercent)

func distFromTargetBodyPos():
	return bodyTargetPos-bodyController.newPos

func calcForce() -> Vector3:
	# jumping
	if velocity.y > jumpSpeed or not grounded:
		jumping = false
	if jumping:
		return Vector3.UP * maxLegForce
	# setup values
	var target = targetPos
	var distance = target-newPos
	var newForce = distance
	var mass = effectiveMass
	var vel = velocity
	# lifting
	if lifting and stepOrigin.y <= targetPos.y:
		target.y = targetPos.y + legStepHeight
	if lifting and stepOrigin.y > targetPos.y:
		target.y = stepOrigin.y + legStepHeight
	if newPos.y >= target.y and lifting:
		lifting = false
	# is moving body or foot
	var forceReq = Globals.gravity*mass
	if grounded and target.y > newPos.y+0.001 or not grounded:
		mass = legMass
		if distance.y < 0.0:
			forceReq = 0.0
		else:
			forceReq = -Globals.gravity*mass
	elif grounded:
		var DFTBP = distFromTargetBodyPos()
		if moveTo:
			distance = DFTBP
			newForce.x = DFTBP.x
			newForce.z *= DFTBP.z
		else:
			distance.y = DFTBP.y
			newForce.x = 0.0
			newForce.z = 0.0
		if distance.y < 0.0:
			forceReq = 0.0
		vel = bodyController.velocity
	newForce.y = forceReq*1.1
	if getSign(distance.y) == getSign(vel.y):
		var brakeA
		if not grounded:
			brakeA = calcBreakAcceleration(distance.y, vel.y, 0.0, 0.0, Globals.gravity)
		if grounded:
			brakeA = -calcBreakAcceleration(distance.y, vel.y, 0.0, 0.0, Globals.gravity+bodyController.getAppliedAcceleration())
		var brakeForce = clamp(brakeA*mass, -maxLegForce, maxLegForce)
		if getMagnitude(brakeForce) > maxLegForce*0.5 or grounded and brakeA > -0.5:
			if grounded:
				brakeForce = min(brakeForce, 0.0)
			#print("is braking with force "+str(brakeForce))
			newForce.y = brakeForce
	return newForce

func move():
	# setup
	oldPos = newPos
	var timeStep = 1.0/bodyController.simFPS
	if grounded:
		var bend = (newPos.y-bodyController.newPos.y)/legLength
		appliedMass = bodyController.mass*(1.0-bend)/bodyController.getGroundedLegCount()
		effectiveMass = bodyController.mass/bodyController.getGroundedLegCount()
	else:
		effectiveMass = legMass
		appliedMass = legMass
	if grounded:
		force = calcForce()
	else:
		force = calcForce()
	# Forces and physics:
	var appliedForce:Vector3 = force+Vector3(0.0, Globals.gravity*appliedMass, 0.0)
	#print(appliedForce.y/bodyController.mass*2.0-Globals.gravity)
	var a:Vector3 = appliedForce/legMass
	velocity += a*timeStep
	newPos += velocity*timeStep
	# correction
	## move foot if it's further away than the leg length
	var root = bodyController.newPos+origin.rotated(Vector3.UP, bodyController.phi)
	root.y = bodyController.newPos.y+legLength
	var Dist = (root-newPos)
	if Dist.length() > legLength:
		var diff = root-Dist*legLength/Dist.length()
		newPos = diff
	## make sure the foot isn't unaturally high compared to the body right now it's 0.8*leglength
	if newPos.y-bodyController.newPos.y > legLength*0.8:
		if grounded:
			bodyController.velocity.y = max(bodyController.velocity.y, 0.0)
			bodyController.newPos.y = newPos.y-legLength*0.8
		velocity.y = bodyController.velocity.y
		newPos.y = bodyController.newPos.y+legLength*0.8
	# check grounded
	var start = oldPos
	var end = newPos
	start.y += 0.1
	end.y -= 0.1
	var result = castRay(start, end)
	if result:
		if result.position.y >= newPos.y and velocity.y < 0.0:
			grounded = true
			velocity = Vector3(0.0, 0.0, 0.0)
			bodyController.velocity += -(appliedForce)/(bodyController.mass)*timeStep
			newPos.y = result.position.y
		else:
			grounded = false
	else:
		grounded = false

func setTarget(pos:Vector3, speed:Vector3):
	targetPos = pos
	targetSpeed = speed
func step(pos:Vector3, speed:Vector3):
	#stepping = true
	#lifting = true
	stepOrigin = newPos
	setTarget(pos, speed)
