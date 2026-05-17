extends Node3D
@export var bodyControl:bodyController

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Jump"):
		bodyControl.enterWalking()
	if Input.is_action_just_pressed("Forward"):
		if Globals.gravity < -1.3:
			Globals.gravity = -1.3
		else:
			Globals.gravity = -9.8
	pass
