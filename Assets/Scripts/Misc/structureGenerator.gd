@tool
extends Node3D

@export_category("Structure")
@export var crewSize:int = 20
@export_category("Meshes")
var floor:ProceduralModel
@export var floorMesh:Mesh
@export var wallStartMesh:Mesh
@export var wallMesh:Mesh
@export var innerCornerMesh:Mesh
@export var innerCornerStartMesh:Mesh
@export var outerCornerMesh:Mesh
@export var outerCornerStartMesh:Mesh
@export_category("Instances")
@export var bedInstance:PackedScene
@export var bedOccupied:Array[Vector2i]
@export_category("Mesh Generation")
@export var CPS:int = 10000
var CPSTimer:float = 0.0
@export var setMeshEachStep:bool = false
@export var clearDataOnMeshCompletion = false
@export_tool_button("Generate furniture", "Bake") var genFurToolButton = generateFurniture

var cells:Array[genCell] = []
var rng = RandomNumberGenerator.new()
var mesh:MeshInstance3D
var collisionShape:CollisionShape3D
var label:Label3D

var generatingMesh = false
var meshArrays = []
var meshMaterials = []
var meshCellIndex = 0
var meshGenerationStartTime
var meshModelArrays = []
var meshModelNames = []
var meshModelMaterials = []

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

func setMesh():
	var arrayMesh:ArrayMesh
	arrayMesh = ArrayMesh.new()
	for i in range(len(meshArrays)):
		var array = meshArrays[i]
		var material = meshMaterials[i]
		arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
		arrayMesh.surface_set_material(i, material)
	var shape = arrayMesh.create_trimesh_shape()
	collisionShape.shape = shape
	mesh.mesh = arrayMesh

func addMeshes(cellIndex:int, arrays:Array, materials:Array, modelNames:Array, modelArrays:Array, modelMaterials:Array):
	var cell = cells[cellIndex]
	var p:int = round(float(cellIndex)/float(len(cells))*100000.0)
	if p % 5000 == 0:
		label.text = "Generating mesh\n"+str(p/1000)+"%"
	for model in cell.models:
		for i in cell.instances:
			var instance = i.instantiate()
			instance.position += Vector3(cell.pos.x, 0.0, cell.pos.y)
			$Instances.add_child(instance)
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
	if meshCellIndex == len(cells) - 1:
		setMesh()
		var time:float = float(Time.get_ticks_msec() - meshGenerationStartTime)/1000.0
		generatingMesh = false
		if clearDataOnMeshCompletion:
			cells = []
		meshArrays = []
		meshCellIndex = -1
		meshMaterials = []
		meshModelArrays = []
		meshModelNames = []
		meshModelMaterials = []
		label.text = "Done\nTook "+str(time)+" seconds"

func onButtonPressed(command:String):
	if command == "generate furniture":
		generateFurniture()
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
		meshGenerationStartTime = Time.get_ticks_msec()

func isSpaceEmpty(spaces:Array[Vector2i]) -> bool:
	for space in spaces:
		var cell = findCell(space.x, space.y)
		if cell:
			return false
	return true

func isSpaceFloor(spaces:Array[Vector2i]) -> bool:
	for space in spaces:
		var cell = findCell(space.x, space.y)
		if not cell or cell.type != "Floor":
			return false
	return true

func addFurniture(furniture:PackedScene, occupied:Array[Vector2i], x:int, y:int) -> void:
	for pos in occupied:
		var gridX = pos.x+x
		var gridY = pos.y+y
		var cell = findCell(gridX, gridY)
		cell.type = "Furniture"
		if pos == Vector2i.ZERO:
			cell.addInstance(furniture)

func addWall(from:Vector2i, to:Vector2i, height:float, rot:int = -1) -> void:
	var diff = to-from
	var dir:Vector2i
	var length = max(abs(diff.x), abs(diff.y)) + 1
	var heightN:int = round(height/0.5)
	if diff.x > 0 and diff.y == 0:
		rot = 0
		dir = Vector2i(1, 0)
	if diff.x < 0 and diff.y == 0:
		rot = 2
		dir = Vector2i(-1, 0)
	if diff.y > 0 and diff.x == 0:
		rot = 1
		dir = Vector2i(0, 1)
	if diff.y < 0 and diff.x == 0:
		rot = 3
		dir = Vector2i(0, -1)
	for i in range(length):
		var pos = from+dir*i
		var cell = findCell(pos.x, pos.y)
		cell.type = "Wall"
		for x in range(2):
			var wallStart = ProceduralModel.new([Vector2i.ZERO], "WallStart", wallStartMesh, Vector3(0.5*x, 0.0, 0.5), rot, Vector2(0.5, 0.5))
			for y in range(heightN-1):
				var wall = ProceduralModel.new([Vector2i.ZERO], "Wall", wallMesh, Vector3(0.5*x, 0.5+0.5*y, 0.5), rot, Vector2(0.5, 0.5))
				cell.models.append(wall)
			cell.models.append(wallStart)

## corners have to be supplied sorted clockwise and the line between them have to be straight
func addWallFromCorners(corners:Array[Vector2i], height:float, connectEnd:bool = true):
	var heightN:int = round(height/0.5)
	var cornerNum = len(corners)
	if not connectEnd: cornerNum -= 1
	for i in range(cornerNum):
		var inner = true
		var corner = corners[i]
		var cornerCell = findCell(corner.x, corner.y)
		var nextIndex = i + 1
		var rot = 0
		var wallRot = 0
		if nextIndex > len(corners)-1: nextIndex -= len(corners)
		var nextCorner = corners[nextIndex]
		var dir = sign(nextCorner-corner)
		var lastIndex = i - 1
		if lastIndex < 0: lastIndex += len(corners)
		var lastCorner = corners[lastIndex]
		var diff = sign(nextCorner-lastCorner)
		var diff1 = sign(corner-lastCorner)
		var diff2 = sign(nextCorner-corner)
		if diff1.x > 0 and diff2.y < 0 or diff1.x < 0 and diff2.y > 0 or diff1.y > 0 and diff2.x > 0 or diff1.y < 0 and diff2.x < 0:
			inner = false
		if diff.x > 0 and diff.y > 0:
			rot = 0
		if diff.x < 0 and diff.y > 0:
			rot = 1
		if diff.x < 0 and diff.y < 0:
			rot = 2
		if diff.x > 0 and diff.y < 0:
			rot = 3
		if diff2.x > 0 and diff2.y == 0:
			wallRot = 0
		if diff2.y > 0 and diff2.x == 0:
			wallRot = 1
		if diff2.x < 0 and diff2.y == 0:
			wallRot = 2
		if diff2.y < 0 and diff2.x == 0:
			wallRot = 3
		cornerCell.type = "Wall"
		var cornerStartModel
		var rot2 = rot+1
		if rot2 > 3: rot2-=4
		var length = max(abs(nextCorner.x-corner.x), abs(nextCorner.y-corner.y))
		if connectEnd or i > 0:
			if inner:
				cornerStartModel = ProceduralModel.new([Vector2i.ZERO], "InnerCornerStart", innerCornerStartMesh, Vector3(0.0, 0.0, 0.5), rot, Vector2(0.5, 0.5))
			else:
				cornerStartModel = ProceduralModel.new([Vector2i.ZERO], "OuterCornerStart", outerCornerStartMesh, Vector3(0.5, 0.0, 0.5), rot2, Vector2(0.5, 0.5))
				var extraWallStartModel1 = ProceduralModel.new([Vector2i.ZERO], "WallStart", wallStartMesh, Vector3(0.0, 0.0, 0.5), rot2, Vector2(0.5, 0.5))
				var extraWallStartModel2 = ProceduralModel.new([Vector2i.ZERO], "WallStart", wallStartMesh, Vector3(0.5, 0.0, 0.5), rot, Vector2(0.5, 0.5))
				cornerCell.models.append(extraWallStartModel1)
				cornerCell.models.append(extraWallStartModel2)
			cornerCell.models.append(cornerStartModel)
			for n in range(heightN-1):
				var cornerModel
				if inner:
					cornerModel = ProceduralModel.new([Vector2i.ZERO], "InnerCorner", innerCornerMesh, Vector3(0.0, 0.5*n+0.5, 0.5), rot, Vector2(0.5, 0.5))
				else:
					cornerModel = ProceduralModel.new([Vector2i.ZERO], "OuterCorner", outerCornerMesh, Vector3(0.5, 0.5*n+0.5, 0.5), rot2, Vector2(0.5, 0.5))
					var extraWallModel1 = ProceduralModel.new([Vector2i.ZERO], "Wall", wallMesh, Vector3(0.0, 0.5*n+0.5, 0.5), rot2, Vector2(0.5, 0.5))
					var extraWallModel2 = ProceduralModel.new([Vector2i.ZERO], "Wall", wallMesh, Vector3(0.5, 0.5*n+0.5, 0.5), rot, Vector2(0.5, 0.5))
					cornerCell.models.append(extraWallModel1)
					cornerCell.models.append(extraWallModel2)
				cornerCell.models.append(cornerModel)
			if i == len(corners)-2 and not connectEnd:
				addWall(corner+dir, nextCorner, height, wallRot)
			elif length > 1:
				addWall(corner+dir, nextCorner-dir, height, wallRot)
		elif i == 0:
			addWall(corner, nextCorner-dir, height, wallRot)
		else:
			addWall(corner, nextCorner, height, wallRot)
func addFloorFromArray(spaces:Array[Vector2i]):
	for space in spaces:
		addCell(genCell.new(space.x, space.y, "Floor", [floor]))

func addFloor(from:Vector2i, to:Vector2i):
	var diff = to-from
	var dir = sign(diff)
	for x in range(abs(diff.x)+1):
		for y in range(abs(diff.y)+1):
			var pos = Vector2i(dir.x*x+from.x, dir.y*y+from.y)
			addCell(genCell.new(pos.x, pos.y, "Floor", [floor]))

func generateSleepingRoom():
	addFloor(Vector2i(0, 0), Vector2i(50, 50))
	var corners:Array[Vector2i] = []
	corners.append(Vector2i(0, 1))
	corners.append(Vector2i(4, 1))
	corners.append(Vector2i(4, 2))
	corners.append(Vector2i(1, 2))
	corners.append(Vector2i(1, 0))
	corners.append(Vector2i(0, 0))
	addWallFromCorners(corners, 2.5, false)
	corners.reverse()
	#addWallFromCorners(corners, 2.5, true)

func generateFurniture():
	cells = []
	var children = $Instances.get_children()
	for child in children:
		child.queue_free()
	generateSleepingRoom()
	generatingMesh = true
	meshGenerationStartTime = Time.get_ticks_msec()
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	floor = ProceduralModel.new([Vector2i(0, 0)], "Floor", floorMesh, Vector3.ZERO, 0, Vector2(0.5, 0.5))
	label = $Label3D
	mesh = $MeshInstance3D
	collisionShape = $StaticBody3D/CollisionShape3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if generatingMesh:
		CPSTimer += delta
		var CPSTime = 1.0/CPS
		while CPSTimer > CPSTime and generatingMesh:
			CPSTimer -= CPSTime
			addMeshes(meshCellIndex, meshArrays, meshMaterials, meshModelNames, meshModelArrays, meshModelMaterials)
			meshCellIndex += 1
		if setMeshEachStep and generatingMesh:
			setMesh()
