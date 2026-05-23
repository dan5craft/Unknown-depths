extends Node3D
@export var bodyControl:bodyController

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
	moveDirection = moveDirection.normalized()
	if moveDirection.length() > 0.0:
		bodyControl.moveDirection = moveDirection
		if bodyControl.state != "Walking":
			bodyControl.enterWalking()
	else:
		if bodyControl.state != "Standing":
			bodyControl.enterStanding()
	pass
