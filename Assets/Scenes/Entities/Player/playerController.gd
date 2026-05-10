extends Node3D

var velocity := Vector3(0.0, 0.0, 0.0)
var movementVector := Vector3(0.0, 0.0, 0.0)

func _read() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Forward"):
		movementVector.z += 1.0
	elif event.is_action_released("Forward"):
		movementVector.z += -1.0
	if event.is_action_pressed("Back"):
		movementVector.z += -1.0
	elif event.is_action_released("Back"):
		movementVector.z += 1.0
	if event.is_action_pressed("Left"):
		movementVector.x += 1.0
	elif event.is_action_released("Left"):
		movementVector.x += -1.0
	if event.is_action_pressed("Right"):
		movementVector.x += -1.0
	elif event.is_action_released("Right"):
		movementVector.x += 1.0

func _process(delta: float) -> void:
	velocity += movementVector.normalized()*delta*0.1
	velocity = lerp(velocity, Vector3(0.0, 0.0, 0.0), min(5.0*delta, 1.0))
	position += velocity
	pass
