extends RigidBody3D

@export var lifetime:float
@export var water:Node3D
@export var radius:float
var timer := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var meshInstance = $MeshInstance3D
	meshInstance.mesh.radius = radius
	meshInstance.mesh.height = radius*2
	var material:BaseMaterial3D = $MeshInstance3D.get_surface_override_material(0)
	var absorption = exp(-Globals.waterAbsorption*(radius*2))
	material.albedo_color = Color(Globals.waterColor.r*absorption, Globals.waterColor.g*absorption, Globals.waterColor.b*absorption, 1.0-absorption)
	var colShape = $CollisionShape3D
	colShape.shape.radius = radius*0.5
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if(timer > lifetime):
		queue_free()
	if(water.isUnderwater(Vector3(global_position.x, global_position.y-radius*1.05, global_position.z))):
		var coord = water.globalToWaterCoord(global_position)
		var volume = 4.0/3.0*PI*pow(radius, 3.0)
		var area = PI*pow(radius, 2.0)
		water.addWaterArea(coord.x, coord.y, volume, area)
		queue_free()
	pass
