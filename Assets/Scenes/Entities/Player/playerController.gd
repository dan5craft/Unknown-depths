extends Node3D
@export var bodyControl:bodyController
@export var sprintSpeed:float = 5.0
@export var walkSpeed:float = 2.0
@export var standingPercent:float = 1.0
@export var crouchingPercent:float = 0.5

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	pass

func _process(delta: float) -> void:
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
