extends Node3D

func onButtonPressed(command:String):
	if command == "generate furniture":
		var sphere = RigidBody3D.new()
		sphere.position = Vector3(0.0, 1.0, 0.0)
		var collision = CollisionShape3D.new()
		collision.shape = SphereShape3D.new()
		var mesh = MeshInstance3D.new()
		mesh.mesh = SphereMesh.new()
		sphere.add_child(collision)
		sphere.add_child(mesh)
		add_child(sphere)



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
