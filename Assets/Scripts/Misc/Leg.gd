class_name Leg extends Node3D

@export var stepHeight = 0.5
@export var legLength = 1.0
@export var body:Node3D
@export var bodyController:Node3D
@export var maxStepTime:float = 0.5
var stepTime:float = 1.0
@export var isSymmetrical:bool = false
@export var symmetricalEqual:Leg

var targetPos:Vector3
var stepping := false
var origin:Vector3
var stepOrigin:Vector3
var stepOriginTime:float

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
	print(Dist)
	return Dist

func dist2D() -> Vector2:
	var root = body.global_position+origin
	root.y = body.global_position.y+legLength
	var Dist = root-global_position
	return Vector2(Dist.x, Dist.z)

func tooFar() -> bool:
	var Dist = dist()
	if Dist > legLength:
		return true
	else:
		return false

func stepFunction(x:float, p1:Vector2, p2:Vector2, p3:Vector2) -> float:
	var part1:float = (x-p2.x)*(x-p3.x)/((p1.x-p2.x)*(p1.x-p3.x))*p1.y
	var part2:float = (x-p1.x)*(x-p3.x)/((p2.x-p1.x)*(p2.x-p3.x))*p2.y
	var part3:float = (x-p1.x)*(x-p2.x)/((p3.x-p1.x)*(p3.x-p2.x))*p3.y
	return part1+part2+part3

func move():
	var time = Time.get_ticks_msec()
	var endTime = stepOriginTime+round(stepTime*1000)
	if time > endTime:
		stepping = false
		global_position = targetPos
		return
	var p = (time-stepOriginTime)/(endTime-stepOriginTime)
	global_position.x = stepOrigin.x+(targetPos.x-stepOrigin.x)*p
	global_position.z = stepOrigin.z+(targetPos.z-stepOrigin.z)*p
	var diff = stepOrigin.y-targetPos.y
	global_position.y = stepFunction(p, Vector2(0.0, 0.0), Vector2(0.5, stepHeight-min(diff, 0.0)), Vector2(1.0, -diff))+stepOrigin.y

func step(pos:Vector3):
	stepping = true
	targetPos = pos
	stepOrigin = global_position
	stepOriginTime = Time.get_ticks_msec()
