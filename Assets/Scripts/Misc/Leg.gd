class_name Leg extends Node3D

@export var legLength = 1.0
@export var stepHeight = 0.3
@export var body:Node3D
@export var bodyController:bodyController
@export var maxStepTime:float = 0.5
@export var maxAngle:float = 20.0
var stepTime:float = 0.5
@export var isSymmetrical:bool = false
@export var symmetricalEqual:Leg
var timer:float

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

func stepFunction(t:float) -> float:
	var val = targetPos.y-stepOrigin.y
	if t < stepTime:
		var offset = sigmoid(t, stepTime, targetPos.y-stepOrigin.y)
		val = sin(t*2.0*PI/stepTime-PI/2.0)*stepHeight/2.0+stepHeight/2.0 + offset
	return val

func move():
	oldPos = newPos
	if stepping:
		var t = timer-stepOriginTime
		if t >= stepTime:
			stepping = false
		newPos.y = stepOrigin.y + stepFunction(t)
		newPos.x = stepOrigin.x + sigmoid(t, stepTime, targetPos.x-stepOrigin.x)
		newPos.z = stepOrigin.z + sigmoid(t, stepTime, targetPos.z-stepOrigin.z)

func step(pos:Vector3, time:float):
	stepping = true
	stepOrigin = newPos
	stepOriginTime = timer
	var start = pos + Vector3.UP*legLength
	var end = pos + Vector3.DOWN*legLength/2.0
	var result = castRay(start, end)
	if result:
		grounded = true
		pos.y = result.position.y
	else:
		grounded = false
	targetPos = pos
	stepTime = time
