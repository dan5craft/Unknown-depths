@tool
extends Node3D
@export var subCameras : Array[Camera3D]
@export var mainCamera : Camera3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for camera in subCameras:
		camera.position = mainCamera.global_position
		camera.rotation = mainCamera.rotation
		camera.fov = mainCamera.fov
	pass
