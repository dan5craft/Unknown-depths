extends Node3D

@export var spawnInterval:float = 0.5
@export var emissionObject:PackedScene
@export var emitter:Node3D
@export var force:Vector3 = Vector3(0.0, 0.0, 0.0)
@export var lifetime:float = 20.0
@export var minRadius:float = 0.1
@export var maxRadius:float = 0.25
@export var coneDeg:float = 45.0
@export var disabled:bool = false
@export var water:Node3D
var timer:float = 0.0
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(disabled):
		return
	timer += delta
	while(timer > spawnInterval):
		timer -= spawnInterval
		var obj:RigidBody3D = emissionObject.instantiate()
		var appliedForce := force
		var phi = deg_to_rad(coneDeg/2.0)
		var r1 = rng.randf_range(-phi, phi)
		var r2 = rng.randf_range(-phi, phi)
		var r3 = rng.randf_range(-phi, phi)
		appliedForce = appliedForce.rotated(Vector3(1.0, 0.0, 0.0), rotation.x+r1)
		appliedForce = appliedForce.rotated(Vector3(0.0, 1.0, 0.0), rotation.y+r2)
		appliedForce = appliedForce.rotated(Vector3(0.0, 0.0, 1.0), rotation.z+r3)
		obj.lifetime = lifetime
		obj.water = water
		var r = rng.randf_range(minRadius, maxRadius)
		obj.radius = r
		emitter.add_child(obj)
		obj.apply_force(appliedForce)
	pass
