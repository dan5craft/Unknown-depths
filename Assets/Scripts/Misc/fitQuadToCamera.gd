@tool
extends MeshInstance3D
@export var distanceFromCamera = 0.02
@export var camera : Camera3D

var underWater : bool = false
@export var insideHull : bool = false
const rayLength = 1000
@export var water : Node3D
# Called every frame. 'delta' is the elapsed time since the previous frame.

#func _physics_process(delta: float) -> void:
	#var space_state = get_world_3d().direct_space_state
	#var query = PhysicsRayQueryParameters3D.create(camera.global_position, Vector3.UP*rayLength)
	#query.exclude = [self]
	#var result = space_state.intersect_ray(query)
	#if result && result["collider"].name == "WaterCollision":
		#visible = true
	#query = PhysicsRayQueryParameters3D.create(camera.global_position, Vector3.DOWN*rayLength)
	#query.exclude = [self]
	#result = space_state.intersect_ray(query)
	#if result && result["collider"].name == "WaterCollision":
		#visible = false

func _process(delta: float) -> void:
	if camera.position.y <= water.position.y and not insideHull:
		underWater = true
	else:
		underWater = false
	if underWater:
		visible = true
		water.get_child(0).visible = true
		water.get_child(1).visible = false
	elif insideHull:
		visible = false
		water.get_child(0).visible = true
		water.get_child(1).visible = false
	else:
		visible = false
		water.get_child(0).visible = false
		water.get_child(1).visible = true
	var size = tan(deg_to_rad(camera.fov/2))*distanceFromCamera
	mesh.size.x = size*5
	mesh.size.y = size*2.1
	position = Vector3.ZERO
	position.z -= distanceFromCamera
