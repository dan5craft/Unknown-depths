extends Node3D
@export var bodyControl:bodyController

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Jump"):
		bodyControl.legs[0].targetPos.y += 0.1
		print("Jumped")
	pass
