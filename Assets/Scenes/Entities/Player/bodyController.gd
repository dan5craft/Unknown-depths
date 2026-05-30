class_name bodyController extends Node3D

@export_category("Body Controller")
@export var legs:Array[Leg]
@export var body:Node3D
@export var mass:float = 80.0
@export var simFPS:int = 15
@export var smoothFPS:bool = true
@export var timeScale = 1.0
var velocity:Vector3 = Vector3(0.0, 0.0, 0.0)
@export_enum("Standing", "Walking") var state:String
@export_category("Legs")
@export var standingPercent = 0.9
@export var stepLength:float = 0.4
@export_subgroup("Movement")
@export var moveDirection:Vector3 = Vector3(0.0, 0.0, 1.0)
@export var movementSpeed = 1.0
@export var movementAcceleration = 5.0
var phi = 0.0

var oldPos:Vector3 = Vector3(0.0, 0.0, 0.0)
var newPos:Vector3 = Vector3(0.0, 0.0, 0.0)
var timer:float = -3.0


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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	oldPos = body.global_position
	newPos = body.global_position
	enterWalking()
	pass # Replace with function body.

func enterStanding() -> void:
	state = "Standing"

func standing() -> void:
	if velocity.length() > 0.0:
		var timeStep = 1.0/simFPS
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
		var root = leg.origin.rotated(Vector3.UP, phi)+newPos
		root.y = newPos.y+leg.legLength
		var Dist = leg.newPos - root
		var Dist2D = Vector3(Dist.x, 0.0, Dist.z)
		if Dist2D.length() > 0.1 and velocity.length() == 0.0 and not leg.stepping:
			if leg.isSymmetrical and not leg.symmetricalEqual.stepping or not leg.isSymmetrical:
				var stepTime = 0.5
				leg.step(leg.origin.rotated(Vector3.UP, phi)+newPos, stepTime)
		leg.move()

func enterWalking() -> void:
	state = "Walking"
	#legs[0].step(legs[0].origin.rotated(Vector3.UP, phi)+newPos+moveDirection*stepLength, 0.5)
	legs[0].step(legs[0].origin.rotated(Vector3.UP, phi)+newPos+Vector3(0.0, 0.0, 0.3), 0.5)

func walking():
	for leg in legs:
		leg.move()
	#var timeStep = 1.0/simFPS
	#var dir = moveDirection.abs()
	#if moveDirection.x == 0.0:
		#if velocity.x > 0.0 or velocity.x < 0.0:
			#dir.x = 1.0
	#if moveDirection.z == 0.0:
		#if velocity.z > 0.0 or velocity.z < 0.0:
			#dir.z = 1.0
	#dir = dir.normalized()
	#var a = dir*movementAcceleration*timeStep
	#var maxVel = moveDirection*movementSpeed
	#print(maxVel)
	#print(velocity)
	#if velocity.x < maxVel.x:
		#velocity.x = min(velocity.x+a.x, maxVel.x)
	#elif velocity.x > maxVel.x:
		#velocity.x = max(velocity.x-a.x, maxVel.x)
	#if velocity.z < maxVel.z:
		#velocity.z = min(velocity.z+a.z, maxVel.z)
	#elif velocity.z > maxVel.z:
		#velocity.z = max(velocity.z-a.z, maxVel.z)
	#if moveDirection.length() == 0.0 and velocity.length() < 0.1:
		#enterStanding()
		#return
	#for leg in legs:
		#var root = leg.origin.rotated(Vector3.UP, phi)+newPos
		#root.y = newPos.y+leg.legLength
		#var Dist = leg.newPos - root
		#var Dist2D = Vector3(Dist.x, 0.0, Dist.z)
		#var angle = rad_to_deg(atan(sqrt(pow(Dist.x, 2.0)+pow(Dist.z, 2.0))/-Dist.y))
		#if Dist.dot(velocity) > 0.0:
			#angle *= -1.0
		#if angle > leg.maxAngle and not leg.stepping:
			#if leg.isSymmetrical and not leg.symmetricalEqual.stepping or not leg.isSymmetrical:
				#var stepTime = 0.1
				#if velocity.length() > 0.0:
					#stepTime = clamp(Dist2D.length()/velocity.length(), 0.1, 0.5)
				#leg.step(leg.origin.rotated(Vector3.UP, phi)+newPos+velocity*stepTime+(velocity.abs()/2.0).min(Vector3(stepLength, 0.0, stepLength))*sign(velocity), stepTime)
		#leg.move()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	var timeStep = 1.0/simFPS
	while timer > timeStep/timeScale:
		timer -= timeStep/timeScale
		for leg in legs:
			leg.timer += timeStep
		oldPos = newPos
		newPos += velocity*timeStep
		#newPos.y = lerp(newPos.y, lowest.newPos.y-lowest.legLength*(1.0-standingPercent), min(5.0*timeStep, 1.0))
		if state == "Standing":
			standing()
		if state == "Walking":
			walking()
	if smoothFPS:
		var timePercent = timer/(timeStep/timeScale)
		body.global_position = lerp(oldPos, newPos, timePercent)
		for leg in legs:
			leg.global_position = lerp(leg.oldPos, leg.newPos, timePercent)
	else:
		body.global_position = newPos
		for leg in legs:
			leg.global_position = leg.newPos
