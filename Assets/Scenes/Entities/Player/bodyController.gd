class_name bodyController extends Node3D

var time := 0.0
@export_category("Body Controller")
@export var legs:Array[Leg]
@export var body:Node3D
@export var mass:float = 80.0
@export var simFPS:int = 60
@export var smoothFPS:bool = true
@export var timeScale = 0.1
var velocity:Vector3 = Vector3(0.0, -0.1, 0.0)
@export_enum("Standing", "Walking") var state:String
@export_category("Legs")
@export var standingPercent = 0.9
@export var stepLength:float = 0.4
@export_subgroup("Movement")
@export var moveDirection:Vector2 = Vector2(1.0, 0.0)
@export var movementSpeed = 0.5
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
		if leg.grounded:
			sum+=1
	return sum

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	oldPos = body.global_position
	newPos = body.global_position
	enterWalking()
	pass # Replace with function body.

func enterStanding() -> void:
	state = "Standing"
	for leg in legs:
		leg.step(leg.origin.rotated(Vector3.UP, phi)+body.global_position)

func standing() -> void:
	var planted = false
	if not planted:
		planted = true
		for leg in legs:
			if leg.stepping:
				leg.move()
				planted = false

func enterWalking() -> void:
	state = "Walking"
	for leg in legs:
		leg.step(leg.origin+newPos+Vector3(0.0, 0.0, 2.0))

func walking():
	for leg in legs:
		leg.move()
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
