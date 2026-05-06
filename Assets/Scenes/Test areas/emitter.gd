extends Node3D

@export var spawnInterval:float = 0.5
@export var emissionObject:PackedScene
@export var emitter:Node3D
@export var force:Vector3 = Vector3(0.0, 0.0, 0.0)
@export var lifetime:float = 20.0
var timer:float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	while(timer > spawnInterval):
		timer -= spawnInterval
		var obj:RigidBody3D = emissionObject.instantiate()
		var appliedForce := force
		appliedForce = appliedForce.rotated(Vector3(1.0, 0.0, 0.0), rotation.x)
		appliedForce = appliedForce.rotated(Vector3(0.0, 1.0, 0.0), rotation.y)
		appliedForce = appliedForce.rotated(Vector3(0.0, 0.0, 1.0), rotation.z)
		obj.apply_force(appliedForce)
		obj.lifetime = lifetime
		emitter.add_child(obj)
	pass
