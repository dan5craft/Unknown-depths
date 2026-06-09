@tool
extends Node3D

@export var generateFurnitureButton:Node3D
@export var button2:Node3D
var floor:ProceduralModel
@export var floorMesh:Mesh
@export var wallStartMesh:Mesh
@export var wallMesh:Mesh
@export var bedMesh:Mesh
@export var bedOccupied:Array[Vector2i]
@export var CPF:int = 10
@export_tool_button("Generate furniture", "Bake") var genFurToolButton = generateFurniture

var cells:Array[genCell] = []
var rng = RandomNumberGenerator.new()
var mesh:MeshInstance3D
var collisionShape:CollisionShape3D
var label:Label3D

var generatingMesh = false
var meshArrays
var meshMaterials
var meshCellIndex
var meshGenerationStartTime
var meshModelArrays
var meshModelNames
var meshModelMaterials

func findCell(x:int, y:int):
	if cells.is_empty():
		return false
	var startIndex:int = -1
	var low:int = 0
	var high:int = len(cells)-1
	while low <= high:
		var mid = (high - low)/2 + low
		var val = cells[mid].pos.x
		if(val < x):
			low = mid + 1
		elif(val > x):
			high = mid - 1
		else:
			startIndex = mid
			high = mid - 1
	if startIndex == -1:
		return false
	var endIndex:int = -1
	low = 0
	high = len(cells)-1
	while low <= high:
		var mid = (high - low)/2 + low
		var val = cells[mid].pos.x
		if(val < x):
			low = mid + 1
		elif(val > x):
			high = mid - 1
		else:
			endIndex = mid
			low = mid + 1
	var index:int = -1
	low = startIndex
	high = endIndex
	while low <= high:
		var mid = (high - low)/2 + low
		var val = cells[mid].pos.y
		if(val < y):
			low = mid + 1
		elif(val > y):
			high = mid - 1
		else:
			index = mid
			high = mid - 1
	if index == -1:
		return false
	return cells[index]

func addCell(cell:genCell) -> void:
	var x = cell.pos.x
	var y = cell.pos.y
	var index:int = 0
	var low:int = 0
	var high:int = len(cells)-1
	var multiple:bool = false
	while low <= high:
		var mid = (high - low)/2 + low
		var val = cells[mid].pos.x
		if(val < x):
			low = mid + 1
			index = low
		elif(val > x):
			high = mid - 1
			index = mid
		else:
			index = mid
			high = mid - 1
			multiple = true
	if not multiple:
		cells.insert(index, cell)
		return
	var endIndex:int = 0
	low = 0
	high = len(cells)-1
	while low <= high:
		var mid = (high - low)/2 + low
		var val = cells[mid].pos.x
		if(val < x):
			low = mid + 1
		elif(val > x):
			high = mid - 1
		else:
			endIndex = mid
			low = mid + 1
	low = index
	high = endIndex
	index = 0
	while low <= high:
		var mid = (high - low)/2 + low
		var val = cells[mid].pos.y
		if(val < y):
			low = mid + 1
			index = low
		elif(val > y):
			high = mid - 1
			index = mid
		else:
			print("There is already a cell at X: "+str(x)+" Y: "+str(y))
			return
	cells.insert(index, cell)

func rotateVector(vector:Vector3, point:Vector2, rot:int) -> Vector3:
	var shifted = vector-Vector3(point.x, 0.0, point.y)
	var x = shifted.x*cos(0.5*PI*rot) - shifted.z*sin(0.5*PI*rot)+point.x
	var y = shifted.x*sin(0.5*PI*rot) + shifted.z*cos(0.5*PI*rot)+point.y
	return Vector3(x, vector.y, y)

func addMeshes(cellIndex:int, arrays:Array, materials:Array, modelNames:Array, modelArrays:Array, modelMaterials:Array):
	var cell = cells[cellIndex]
	var p:int = round(float(cellIndex)/float(len(cells))*100000.0)
	if p % 5000 == 0:
		label.text = "Generating mesh\n"+str(p/1000)+"%"
	for model in cell.models:
		var modelMesh = model.mesh
		var modelName = model.name
		var surfaces = []
		var materialArray = []
		if modelNames.count(modelName) == 0:
			modelNames.append(modelName)
			for s in range(modelMesh.get_surface_count()):
				surfaces.append(modelMesh.surface_get_arrays(s))
				materialArray.append(modelMesh.surface_get_material(s))
			modelArrays.append(surfaces.duplicate(true))
			modelMaterials.append(materialArray)
		else:
			var index = modelNames.find(modelName)
			surfaces = modelArrays[index].duplicate(true)
			materialArray = modelMaterials[index]
		for i in range(len(surfaces)):
			var surface = surfaces[i]
			var material = materialArray[i]
			var surfaceIndex = len(arrays)
			var vertexCount = 0
			if materials.count(material) > 0:
				var index = materials.find(material)
				surfaceIndex = index
				vertexCount = len(arrays[index][Mesh.ARRAY_VERTEX])
			else:
				materials.append(material)
				var newArray = []
				newArray.resize(Mesh.ARRAY_MAX)
				arrays.append(newArray)
			for n in range(len(surface[Mesh.ARRAY_INDEX])):
				surface[Mesh.ARRAY_INDEX][n] += vertexCount
			for n in range(len(surface[Mesh.ARRAY_VERTEX])):
				var offset = Vector3(model.pos.x, 0.0, model.pos.z)
				surface[Mesh.ARRAY_VERTEX][n] = rotateVector(surface[Mesh.ARRAY_VERTEX][n]+offset, model.center, model.rot) + Vector3(cell.pos.x, 0.0+model.pos.y, cell.pos.y)
				surface[Mesh.ARRAY_NORMAL][n] = rotateVector(surface[Mesh.ARRAY_NORMAL][n], Vector2.ZERO, model.rot)
			for n in range(len(surface)):
				if arrays[surfaceIndex][n] == null:
					arrays[surfaceIndex][n] = surface[n]
				else:
					arrays[surfaceIndex][n].append_array(surface[n])
	if cellIndex < len(cells) - 1:
		return
	var arrayMesh:ArrayMesh
	arrayMesh = ArrayMesh.new()
	for i in range(len(arrays)):
		var array = arrays[i]
		var material = materials[i]
		arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
		arrayMesh.surface_set_material(i, material)
	var shape = arrayMesh.create_trimesh_shape()
	collisionShape.shape = shape
	mesh.mesh = arrayMesh
	var time:float = float(Time.get_ticks_msec() - meshGenerationStartTime)/1000.0
	generatingMesh = false
	label.text = "Done\nTook "+str(time)+" seconds"

#func addMeshes(arrays:Array, materials:Array, cellIndex:int):
	#var cell = cells[cellIndex]
	#var p:int = round(float(cellIndex)/float(len(cells))*100000.0)
	#if p % 5000 == 0:
		#label.text = "Generating mesh\n"+str(p/1000)+"%"
	#for Procedural in cell.models:
		#var model = Procedural.mesh
		#var modelMesh:ArrayMesh = model.duplicate()
		#for n in range(modelMesh.get_surface_count()):
			#var surface = modelMesh.surface_get_arrays(n)
			#var surface2 = len(arrays)
			#var material = modelMesh.surface_get_material(n)
			#var vertexCount = 0
			#for i in range(len(materials)):
				#var material2 = materials[i]
				#if material.resource_path == material2.resource_path:
					#surface2 = i
			#if surface2 < len(arrays):
				#vertexCount = len(arrays[surface2][Mesh.ARRAY_VERTEX])
			#else:
				#var newArray = []
				#newArray.resize(Mesh.ARRAY_MAX)
				#arrays.append(newArray)
				#materials.append(material)
			#for i in range(len(surface[Mesh.ARRAY_INDEX])):
				#surface[Mesh.ARRAY_INDEX][i] += vertexCount
			#for i in range(len(surface[Mesh.ARRAY_VERTEX])):
				#var offset = Vector3(Procedural.pos.x, 0.0, Procedural.pos.z)
				#surface[Mesh.ARRAY_VERTEX][i] = rotateVector(surface[Mesh.ARRAY_VERTEX][i]+offset, Procedural.center, Procedural.rot) + Vector3(cell.pos.x, 0.0+Procedural.pos.y, cell.pos.y)
				#surface[Mesh.ARRAY_NORMAL][i] = rotateVector(surface[Mesh.ARRAY_NORMAL][i], Vector2.ZERO, Procedural.rot)
			#for i in range(len(surface)):
				#if arrays[surface2][i] == null:
					#arrays[surface2][i] = surface[i]
				#else:
					#arrays[surface2][i].append_array(surface[i])
	#if cellIndex < len(cells) - 1:
		#return
	#label.text = "Setting mesh"
	#var arrayMesh:ArrayMesh
	#arrayMesh = ArrayMesh.new()
	#for i in range(len(arrays)):
		#var array = arrays[i]
		#var material = materials[i]
		#arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
		#arrayMesh.surface_set_material(i, material)
	#var shape = arrayMesh.create_trimesh_shape()
	#collisionShape.shape = shape
	#mesh.mesh = arrayMesh
	#var time:float = float(Time.get_ticks_msec() - meshGenerationStartTime)/1000.0
	#generatingMesh = false
	#label.text = "Done\nTook "+str(time)+" seconds"

func onButtonPressed(command:String):
	if command == "generate furniture":
		generateFurnitureButton.active = false
		generateFurniture()
		button2.active = true
	if command.begins_with("find"):
		var pos = command.erase(0, 4).remove_chars(" ").split(",")
		var x = int(pos[0])
		var y = int(pos[1])
		var cell = findCell(x, y)
		if cell:
			print(cell.type)
		else:
			print("could not find cell on position X: "+str(x)+" Y: "+str(y))
	if command == "generate mesh":
		generatingMesh = true
		meshArrays = []
		meshCellIndex = 0
		meshMaterials = []
		meshModelArrays = []
		meshModelNames = []
		meshModelMaterials = []
		meshGenerationStartTime = Time.get_ticks_msec()
	#if command == "generate mesh":
		#meshGenerationStartTime = Time.get_ticks_msec()
		#addMeshes()
		#var time = float(Time.get_ticks_msec()-meshGenerationStartTime)/1000.0
		#label.text = "Done\nTook "+str(time)+" seconds"

func generateFurnitureCells(furniture:ProceduralModel, x:int, y:int):
	var furnitureCells = []
	for pos in furniture.occupied:
		var models:Array[ProceduralModel] = [floor]
		if pos == Vector2i.ZERO:
			models.append(furniture)
		var cell:genCell = genCell.new(pos.x+x, pos.y+y, "Furniture", models)
		furnitureCells.append(cell)
	return furnitureCells

func generateFurniture():
	for x in range(500):
		for y in range(250):
			#var models:Array[ProceduralModel] = []
			#if rng.randf() < 0.2:
				#var rot = rng.randi_range(0, 3)
				#var rot2 = rot + 2
				#if rot2 > 3: rot2-=4
				#for i in range(2):
					#var wallStart = ProceduralModel.new([Vector2i.ZERO], "WallStart", wallStartMesh, Vector3(i*0.5, 0.0, 0.5), rot, Vector2(0.5, 0.5))
					#var wallStart2 = ProceduralModel.new([Vector2i.ZERO], "WallStart", wallStartMesh, Vector3(i*0.5, 0.0, 0.5), rot2, Vector2(0.5, 0.5))
					#for n in range(3):
						#var wall = ProceduralModel.new([Vector2i.ZERO], "Wall", wallMesh, Vector3(i*0.5, (n+1)*0.5, 0.5), rot, Vector2(0.5, 0.5))
						#var wall2 = ProceduralModel.new([Vector2i.ZERO], "Wall", wallMesh, Vector3(i*0.5, (n+1)*0.5, 0.5), rot2, Vector2(0.5, 0.5))
						#models.append(wall)
						#models.append(wall2)
					#models.append(wallStart)
					#models.append(wallStart2)
			#models.append(floor)
			#var cell:genCell = genCell.new(x, y, "Floor", models)
			var bedCells = generateFurnitureCells(ProceduralModel.new(bedOccupied, "Bed", bedMesh, Vector3.ZERO, 0, Vector2.ZERO), x, y*2)
			for cell in bedCells:
				addCell(cell)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	floor = ProceduralModel.new([Vector2i(0, 0)], "Floor", floorMesh, Vector3.ZERO, 0, Vector2(0.5, 0.5))
	label = $Label3D
	mesh = $MeshInstance3D
	collisionShape = $StaticBody3D/CollisionShape3D
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if generatingMesh:
		for i in range(CPF):
			if meshCellIndex == len(cells):
				break
			addMeshes(meshCellIndex, meshArrays, meshMaterials, meshModelNames, meshModelArrays, meshModelMaterials)
			meshCellIndex += 1
	pass
