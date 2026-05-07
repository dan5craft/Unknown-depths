@tool
extends Node3D

@export var steps:int = 6:
	set(v):
		steps = v
		generateMesh()
@export var height:float = 2:
	set(v):
		height = v
		generateMesh()
@export var width:float = 1.0:
	set(v):
		width = v
		generateMesh()
@export var angle:float = 45.0:
	set(v):
		angle = v
		generateMesh()
@export_tool_button("Generate Stairs", "3D") var genButton = generateMesh

func normal(v1:Vector3, v2:Vector3, v3:Vector3):
	return -(v2-v1).cross(v3-v1).normalized()

func generateMesh():
	if not Engine.is_editor_hint():
		return
	var phi = deg_to_rad(angle)
	var h = height/steps
	var step:ArrayMesh = $step.mesh.duplicate()
	var vertexArray = step.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var normalArray = step.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	var indexArray = step.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	var newMesh:Mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	for i in range(vertexArray.size()):
		vertexArray[i].x = vertexArray[i].x - width/2.0
		vertexArray[i].y = vertexArray[i].y/0.25*h
		vertexArray[i].z = vertexArray[i].z + tan(phi)*vertexArray[i].y
	var newVertexArray:PackedVector3Array = PackedVector3Array()
	var newIndexArray:PackedInt32Array = PackedInt32Array()
	var newNormalArray:PackedVector3Array = PackedVector3Array()
	for i in range(steps-1):
		for n in range(vertexArray.size()):
			var v = vertexArray[n]
			v.y += h*(i+1)
			v.z += tan(phi)*h*(i+1)
			newVertexArray.push_back(v)
		for n in range(indexArray.size()):
			newIndexArray.push_back(indexArray[n]+vertexArray.size()*(i+1))
		newNormalArray.append_array(normalArray)
	vertexArray.append_array(newVertexArray)
	normalArray.append_array(newNormalArray)
	indexArray.append_array(newIndexArray)
	arrays[Mesh.ARRAY_VERTEX] = vertexArray
	arrays[Mesh.ARRAY_NORMAL] = normalArray
	arrays[Mesh.ARRAY_INDEX] = indexArray
	#print(normalArray)
	newMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	for i in range(vertexArray.size()):
		vertexArray[i].x = vertexArray[i].x*-1
		normalArray[i].x = normalArray[i].x*-1
	for i in range(indexArray.size()/3):
		var temp = indexArray[1+i*3]
		indexArray[1+i*3] = indexArray[2+i*3]
		indexArray[2+i*3] = temp
	arrays[Mesh.ARRAY_VERTEX] = vertexArray
	arrays[Mesh.ARRAY_NORMAL] = normalArray
	newMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	vertexArray = PackedVector3Array()
	
	for i in range(steps):
		vertexArray.push_back(Vector3(0.0, (h*(i+1))-0.1, 0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(0.0, (h*(i+1)), 0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(width, (h*(i+1)), 0.25+tan(phi)*h*i))
		
		vertexArray.push_back(Vector3(0.0, (h*(i+1))-0.1, 0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(width, (h*(i+1)), 0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(width, (h*(i+1))-0.1, 0.25+tan(phi)*h*i))
		
		vertexArray.push_back(Vector3(0.0, (h*(i+1))-0.1, -0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(width, (h*(i+1)), -0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(0.0, (h*(i+1)), -0.25+tan(phi)*h*i))
		
		vertexArray.push_back(Vector3(0.0, (h*(i+1))-0.1, -0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(width, (h*(i+1))-0.1, -0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(width, (h*(i+1)), -0.25+tan(phi)*h*i))
		
		vertexArray.push_back(Vector3(0.0, (h*(i+1)), 0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(0.0, (h*(i+1)), -0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(width, (h*(i+1)), 0.25+tan(phi)*h*i))
		
		vertexArray.push_back(Vector3(0.0, (h*(i+1)), -0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(width, (h*(i+1)), -0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(width, (h*(i+1)), 0.25+tan(phi)*h*i))
		
		vertexArray.push_back(Vector3(0.0, (h*(i+1))-0.1, 0.25-tan(phi)*0.15+tan(phi)*h*i))
		vertexArray.push_back(Vector3(0.0, (h*(i+1)), 0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(0.0, (h*(i+1))-0.1, 0.25+tan(phi)*h*i))
		
		vertexArray.push_back(Vector3(width, (h*(i+1))-0.1, 0.25-tan(phi)*0.15+tan(phi)*h*i))
		vertexArray.push_back(Vector3(width, (h*(i+1))-0.1, 0.25+tan(phi)*h*i))
		vertexArray.push_back(Vector3(width, (h*(i+1)), 0.25+tan(phi)*h*i))
	
	arrays[Mesh.ARRAY_VERTEX] = vertexArray
	normalArray = PackedVector3Array()
	for i in range(vertexArray.size()/3):
		vertexArray[0+i*3].x -= width/2.0
		vertexArray[1+i*3].x -= width/2.0
		vertexArray[2+i*3].x -= width/2.0
		vertexArray[0+i*3].z += tan(phi)*h
		vertexArray[1+i*3].z += tan(phi)*h
		vertexArray[2+i*3].z += tan(phi)*h
		for n in range(3):
			normalArray.push_back(normal(vertexArray[0+i*3], vertexArray[1+i*3], vertexArray[2+i*3]))
	arrays[Mesh.ARRAY_NORMAL] = normalArray
	newMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var concrete:Material = load("res://Assets/Models/Objects/proceduralStairs_Concrete.tres")
	var diamondPlate:Material = load("res://Assets/Models/Objects/proceduralStairs_DiamondPlate.tres")
	newMesh.surface_set_material(0, concrete)
	newMesh.surface_set_material(1, concrete)
	newMesh.surface_set_material(2, diamondPlate)
	var collisionShape = newMesh.create_trimesh_shape()
	$stairs/StaticBody3D/CollisionShape3D.shape = collisionShape
	$stairs.mesh = newMesh
	#for i in range(indexArray.size()/3):
		#var v1:Vector3 = vertexArray[indexArray[0+i*3]]
		#var v2:Vector3 = vertexArray[indexArray[1+i*3]]
		#var v3:Vector3 = vertexArray[indexArray[2+i*3]]
		#if(v1.is_equal_approx(corner) || v1.is_equal_approx(corner) || v2.is_equal_approx(corner)):
			#print(str(indexArray[0+i*3])+" "+str(indexArray[1+i*3])+" "+str(indexArray[2+i*3]))
			#print(str(v1)+" "+str(v2)+" "+str(v3))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generateMesh()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
