extends Node3D
@export var bodyControl:bodyController
@export var sprintSpeed:float = 3.0
@export var walkSpeed:float = 1.0

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	pass

func _process(delta: float) -> void:
	#var moveDirection = Vector3.ZERO
	#if Input.is_action_pressed("Forward"):
		#moveDirection.z += 1.0
	#if Input.is_action_pressed("Back"):
		#moveDirection.z -= 1.0
	#if Input.is_action_pressed("Left"):
		#moveDirection.x += 1.0
	#if Input.is_action_pressed("Right"):
		#moveDirection.x -= 1.0
	#if Input.is_action_pressed("Sprint"):
		#bodyControl.movementSpeed = 3.0
	#else:
		#bodyControl.movementSpeed = 1.0
	#moveDirection = moveDirection.normalized()
	#bodyControl.moveDirection = moveDirection
	#if moveDirection.length() > 0.0:
		#if bodyControl.state != "Walking":
			#bodyControl.enterWalking()
	pass
