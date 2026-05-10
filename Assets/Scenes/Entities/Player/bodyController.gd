extends Node3D

var time := 0.0
@export_category("Body Controller")
@export var legs:Array[Leg]
@export var body:Node3D
@export_enum("Standing", "Walking") var state:String
@export_category("Legs")
@export var standingPercent = 0.9
@export var stepLength:float = 0.4
@export_subgroup("Movement")
@export var moveDirection:Vector2 = Vector2(1.0, 0.0)
@export var movementSpeed = 10.0
var phi = 0.0


func castRay(pos1:Vector3, pos2:Vector3) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(pos1, pos2)
	return space_state.intersect_ray(query)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enterStanding()
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
	if planted:
		enterWalking()

func enterWalking() -> void:
	state = "Walking"
	var delta = get_process_delta_time()
	var velocity = Vector3(moveDirection.x*movementSpeed, 0.0, moveDirection.y*movementSpeed)
	legs[0].step(legs[0].origin.rotated(Vector3.UP, phi)+body.global_position+velocity)

func walking():
	var delta = get_process_delta_time()
	if moveDirection.length() > 1.0 or moveDirection.length() < 1.0:
		moveDirection = moveDirection.normalized()
	var velocity = Vector3(moveDirection.x*movementSpeed, 0.0, moveDirection.y*movementSpeed)
	var stepOffset = Vector3(sin(phi), 0.0, cos(phi))*stepLength
	var angle = atan(moveDirection.x/moveDirection.y)
	if moveDirection.y < 0.0:
		angle += PI
	elif moveDirection.x < 0.0:
		angle += 2.0*PI
	phi = lerp(phi, angle, min(1.0*delta, 1.0))
	for leg in legs:
		if leg.tooFar() and not leg.stepping:
			leg.step(leg.origin.rotated(Vector3.UP, phi)+body.global_position+velocity+stepOffset*leg.legLength)
		leg.move()
	body.global_position += velocity*delta
	var targetBasis = Basis.IDENTITY.rotated(Vector3.UP, phi)
	body.basis = body.basis.slerp(targetBasis, min(1.0*delta, 1.0))
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if state == "Standing":
		standing()
	if state == "Walking":
		walking()
	pass
