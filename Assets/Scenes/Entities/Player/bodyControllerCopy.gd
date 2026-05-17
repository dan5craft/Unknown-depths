extends Node3D

var time := 0.0
@export_category("Body Controller")
@export var legs:Array[Leg]
@export var body:Node3D
@export var mass:float = 80.0
@export var simFPS:int = 60
@export var smoothFPS:bool = true
@export var timeScale = 0.1
var velocity:Vector3 = Vector3(0.0, 0.0, 0.0)
@export_enum("Standing", "Walking") var state:String
@export_category("Legs")
@export var standingPercent = 0.9
@export var stepLength:float = 0.5
@export var maxLegAngle:float = 15.0
@export_subgroup("Movement")
@export var moveDirection:Vector2 = Vector2(0.0, 1.0)
@export var movementSpeed = 0.5
var phi = 0.0

var oldPos:Vector3 = Vector3(0.0, 0.0, 0.0)
var newPos:Vector3 = Vector3(0.0, 0.0, 0.0)
var timer:float = -3.0
var targetSpeed:Vector2 = Vector2.ZERO


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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	oldPos = body.global_position
	newPos = body.global_position
	enterStanding()
	pass # Replace with function body.

func enterStanding() -> void:
	state = "Standing"
	for leg in legs:
		leg.setTarget(leg.origin.rotated(Vector3.UP, phi)+newPos, Vector3.ZERO)

func standing() -> void:
	for leg in legs:
		leg.move()

func enterWalking() -> void:
	state = "Walking"
	var pos = legs[0].origin.rotated(Vector3.UP, phi)+newPos+Vector3(moveDirection.x*stepLength, 0.0, moveDirection.y*stepLength)
	var start = pos+Vector3.UP
	var end = pos-Vector3.UP
	var result = castRay(start, end)
	if result:
		pos.y = result.position.y
	legs[0].jump(0.1)
	legs[0].step(pos, Vector3.ZERO)

func walking():
	targetSpeed = moveDirection*movementSpeed
	var maxAngle = 0.0
	var furthest:Leg
	var legTargetSpeed = Vector3(moveDirection.x*movementSpeed, 0.0, moveDirection.y*movementSpeed)
	for leg in legs:
		leg.maxHorizontalSpeed = Vector2(sqrt(pow(moveDirection.x, 2.0))*movementSpeed*4.0, sqrt(pow(moveDirection.y, 2.0))*movementSpeed*4.0)
		var pos = leg.origin.rotated(Vector3.UP, phi)+newPos+Vector3(moveDirection.x*stepLength, 0.0, moveDirection.y*stepLength)
		var start = pos+Vector3.UP
		var end = pos-Vector3.UP
		var result = castRay(start, end)
		if result:
			pos.y = result.position.y
		#if leg.stepping:
			#leg.targetPos = pos
		var root = newPos+leg.origin.rotated(Vector3.UP, phi)
		root.y = newPos.y+leg.legLength
		var Dist = root-leg.newPos
		var angle = rad_to_deg(atan(sqrt(pow(Dist.x, 2.0)+pow(Dist.z, 2.0))/Dist.y))
		if sqrt(pow(angle, 2.0)) > maxAngle and not leg.stepping:
			maxAngle = angle
			furthest = leg
		leg.move()
	if maxAngle > maxLegAngle and getGroundedLegCount() > 1 and not furthest.symmetricalEqual.stepping:
		furthest.jump(0.1)
		furthest.velocity.y = -1.0
		furthest.grounded = true
		var pos = furthest.origin.rotated(Vector3.UP, phi)+newPos+Vector3(moveDirection.x*stepLength, 0.0, moveDirection.y*stepLength)
		furthest.step(pos, legTargetSpeed)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	var timeStep = 1.0/simFPS
	while timer > timeStep/timeScale:
		timer -= timeStep/timeScale
		oldPos = newPos
		var a:Vector3 = Vector3.UP*Globals.gravity
		velocity += a*timeStep
		newPos = oldPos+velocity*timeStep
		phi += timeStep*0.1
		moveDirection = Vector2(cos(phi), sin(phi))
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
