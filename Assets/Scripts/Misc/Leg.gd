class_name Leg extends Node3D

@export var legLength = 1.0
@export var legStepHeight = 0.2
@export var legMass = 5.0
@export var maxLegForce = 400.0
@export var body:Node3D
@export var bodyController:Node3D
@export var maxStepTime:float = 0.5
var stepTime:float = 2.0
@export var isSymmetrical:bool = false
@export var symmetricalEqual:Leg

var targetPos:Vector3
var stepping := false
var origin:Vector3
var stepOrigin:Vector3
var stepOriginTime:float
var velocity:Vector3 = Vector3(0.0, 0.0, 0.0)
var force:Vector3 = Vector3(0.0, 0.0, 0.0)

func _ready() -> void:
	targetPos = global_position
	origin = global_position-body.global_position

func castRay(pos1:Vector3, pos2:Vector3) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(pos1, pos2)
	return space_state.intersect_ray(query)

func dist() -> float:
	var root = body.global_position+origin.rotated(Vector3.UP, bodyController.phi)
	root.y = body.global_position.y+legLength
	var Dist = (root-global_position).length()
	return Dist

func dist2D() -> Vector2:
	var root = body.global_position+origin.rotated(Vector3.UP, bodyController.phi)
	root.y = body.global_position.y+legLength
	var Dist = root-global_position
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

func move():
	var root = body.global_position+origin.rotated(Vector3.UP, bodyController.phi)
	root.y = body.global_position.y+legLength
	var Dist = (root-global_position)
	if Dist.length() > legLength:
		var diff = root-Dist*legLength/Dist.length()
		global_position = diff
	if global_position.y-body.global_position.y > 0.8:
		bodyController.velocity.y = max(bodyController.velocity.y, 0.0)
	var appliedForce:Vector3 = force+Vector3(0.0, Globals.gravity*legMass, 0.0)
	var a:Vector3 = appliedForce/legMass
	velocity += a*get_process_delta_time()
	var newPos = global_position + velocity*get_process_delta_time()
	var start = newPos
	var end = newPos
	start.y += legLength*2.0
	end.y -= legLength*2.0
	var result = castRay(start, end)
	if result:
		if result.position.y > newPos.y:
			newPos.y = result.position.y
			#var impact = legMass*velocity.y/get_process_delta_time()
			var impact = Vector3.ZERO
			bodyController.velocity += -(appliedForce+Vector3.UP*impact)/(bodyController.mass)*get_process_delta_time()
			force = Vector3(0.0, -maxLegForce, 0.0)
			print(Globals.gravity*(bodyController.mass/2.0-legMass))
			velocity = Vector3(0.0, 0.0, 0.0)
	global_position = newPos

func step(pos:Vector3):
	stepping = true
	var start = pos
	var end = pos
	start.y += legLength
	end.y -= legLength
	var result = castRay(start, end)
	if result:
		pos.y = result.position.y
	targetPos = pos
	stepOrigin = global_position
	stepOriginTime = Time.get_ticks_msec()
