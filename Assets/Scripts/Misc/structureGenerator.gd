extends Node3D

@export var generateFurnitureButton:Node3D
@export var button2:Node3D
var floor:ProceduralModel
@export var floorMesh:Mesh
@export var wallStartMesh:Mesh
@export var wallMesh:Mesh
@export var bedMesh:Mesh
@export var bedOccupied:Array[Vector2i]

var cells:Array[genCell] = []
var rng = RandomNumberGenerator.new()
var mesh:MeshInstance3D
var collisionShape:CollisionShape3D

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

func addMeshes():
	var arrayMesh:ArrayMesh
	var vertexCount = 0
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrayMesh = ArrayMesh.new()
	for cell in cells:
		for Procedural in cell.models:
			var model = Procedural.mesh
			var modelMesh:ArrayMesh = model.duplicate()
			for s in range(modelMesh.get_surface_count()):
				var surface = modelMesh.surface_get_arrays(s)
				for i in range(len(surface[Mesh.ARRAY_INDEX])):
					surface[Mesh.ARRAY_INDEX][i] += vertexCount
				for i in range(len(surface[Mesh.ARRAY_VERTEX])):
					var shifted = surface[Mesh.ARRAY_VERTEX][i]-Vector3(Procedural.center.x-Procedural.pos.x, 0.0, Procedural.center.y-Procedural.pos.z)
					var x = shifted.x*cos(0.5*PI*Procedural.rot) - shifted.z*sin(0.5*PI*Procedural.rot)+Procedural.center.x
					var y = shifted.x*sin(0.5*PI*Procedural.rot) + shifted.z*cos(0.5*PI*Procedural.rot)+Procedural.center.y
					surface[Mesh.ARRAY_VERTEX][i] = Vector3(x, surface[Mesh.ARRAY_VERTEX][i].y, y) + Vector3(cell.pos.x, 0.0+Procedural.pos.y, cell.pos.y)
					#print(surface[Mesh.ARRAY_VERTEX][i])
				for i in range(len(surface)):
					if arrays[i] == null:
						arrays[i] = surface[i]
					else:
						arrays[i].append_array(surface[i])
				vertexCount += len(surface[Mesh.ARRAY_VERTEX])
	arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var shape = arrayMesh.create_trimesh_shape()
	collisionShape.shape = shape
	mesh.mesh = arrayMesh
	print(vertexCount)

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
	for x in range(100):
		for y in range(100):
			var models:Array[ProceduralModel] = []
			if rng.randf() < 0.2:
				var rot = rng.randi_range(0, 3)
				var rot2 = rot + 2
				if rot2 > 3: rot2-=4
				for i in range(2):
					var wallStart = ProceduralModel.new([Vector2i.ZERO], "WallStart", wallStartMesh, Vector3(i*0.5, 0.0, 0.5), rot, Vector2(0.5, 0.5))
					var wallStart2 = ProceduralModel.new([Vector2i.ZERO], "WallStart", wallStartMesh, Vector3(i*0.5, 0.0, 0.5), rot2, Vector2(0.5, 0.5))
					for n in range(3):
						var wall = ProceduralModel.new([Vector2i.ZERO], "Wall", wallMesh, Vector3(i*0.5, (n+1)*0.5, 0.5), rot, Vector2(0.5, 0.5))
						var wall2 = ProceduralModel.new([Vector2i.ZERO], "Wall", wallMesh, Vector3(i*0.5, (n+1)*0.5, 0.5), rot2, Vector2(0.5, 0.5))
						models.append(wall)
						models.append(wall2)
					models.append(wallStart)
					models.append(wallStart2)
			models.append(floor)
			var cell:genCell = genCell.new(x, y, "Floor", models)
			#var bedCells = generateFurnitureCells(bed, x, y*2)
			#for cell in bedCells:
			addCell(cell)
	addMeshes()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	floor = ProceduralModel.new([Vector2i(0, 0)], "Floor", floorMesh, Vector3.ZERO, 0, Vector2(0.5, 0.5))
	mesh = $MeshInstance3D
	collisionShape = $StaticBody3D/CollisionShape3D
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
