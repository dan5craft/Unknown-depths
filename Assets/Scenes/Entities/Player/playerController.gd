extends Node3D
@export var bodyControl:bodyController
@export var sprintSpeed:float = 4.0
@export var walkSpeed:float = 1.5
@export var standingPercent:float = 1.0
@export var crouchingPercent:float = 0.5
@export var neckLength = 0.2

var camYRot = 0.0
var camPos

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camPos = $Camera3D.position
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		bodyControl.phi += -event.relative.x*0.001
		camYRot = clamp(camYRot + event.relative.y*0.001, -PI/2.0, PI/2.0)

func _process(delta: float) -> void:
	$Camera3D.basis = $Camera3D.basis.slerp(Basis.IDENTITY.rotated(Vector3.UP, PI).rotated(Vector3.RIGHT, camYRot), min(15.0*delta, 1.0))
	$Camera3D.position.z = sin(camYRot)*neckLength+camPos.z
	$Camera3D.position.y = cos(camYRot)*neckLength+camPos.y-neckLength
	var moveDirection = Vector3.ZERO
	if Input.is_action_pressed("Forward"):
		moveDirection.z += 1.0
	if Input.is_action_pressed("Back"):
		moveDirection.z -= 1.0
	if Input.is_action_pressed("Left"):
		moveDirection.x += 1.0
	if Input.is_action_pressed("Right"):
		moveDirection.x -= 1.0
	if Input.is_action_pressed("Crouch"):
		bodyControl.standingPercent = crouchingPercent
	else:
		bodyControl.standingPercent = standingPercent
	if Input.is_action_pressed("Sprint"):
		bodyControl.movementSpeed = sprintSpeed
		bodyControl.standingPercent = standingPercent
	else:
		bodyControl.movementSpeed = walkSpeed
	moveDirection = moveDirection.normalized()
	bodyControl.moveDirection = moveDirection
	if moveDirection.length() > 0.0:
		if bodyControl.state == "Standing":
			bodyControl.enterWalking()
	pass
