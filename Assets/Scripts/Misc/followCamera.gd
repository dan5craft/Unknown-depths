@tool
extends Camera3D
@export var camera : Camera3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = camera.global_position
	rotation = camera.rotation
	fov = camera.fov
	pass
