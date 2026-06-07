extends Node3D

@export var generateFurnitureButton:Node3D
@export var button2:Node3D
var floor:ProceduralFurniture
@export var floorMesh:Mesh
var bed:ProceduralFurniture
@export var bedMesh:Mesh
@export var bedOccupied:Array[Vector2i]

var cells:Array[genCell] = []
var rng = RandomNumberGenerator.new()
var mesh:MeshInstance3D

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
		addMeshes(cell)
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
	addMeshes(cell)

func addMeshes(cell:genCell):
	var arrayMesh:ArrayMesh
	var vertexCount = 0
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	if mesh.mesh == null:
		arrayMesh = ArrayMesh.new()
	else:
		arrayMesh = mesh.mesh.duplicate()
		arrays = arrayMesh.surface_get_arrays(0)
		vertexCount = len(arrayMesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	for model in cell.models:
		var modelMesh:ArrayMesh = model.duplicate()
		#print(modelMesh.surface_get_arrays(0))
		for s in range(modelMesh.get_surface_count()):
			var surface = modelMesh.surface_get_arrays(s)
			for i in range(len(surface[Mesh.ARRAY_INDEX])):
				surface[Mesh.ARRAY_INDEX][i] += vertexCount
			for i in range(len(surface)):
				if arrays[i] == null:
					arrays[i] = surface[i]
				else:
					arrays[i].append_array(surface[i])
			vertexCount += len(surface[Mesh.ARRAY_VERTEX])
	arrayMesh.clear_surfaces()
	arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.mesh = arrayMesh
	print(arrayMesh.surface_get_arrays(0))

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

func generateFurnitureCells(furniture:ProceduralFurniture, x:int, y:int):
	var furnitureCells = []
	for pos in furniture.occupied:
		var models:Array[Mesh] = [floor.mesh]
		if pos == Vector2i.ZERO:
			models.append(furniture.mesh)
		var cell:genCell = genCell.new(pos.x+x, pos.y+y, "Furniture", models)
		furnitureCells.append(cell)
	return furnitureCells

func generateFurniture():
	for x in range(1):
		for y in range(1):
			var bedCells = generateFurnitureCells(bed, x, y*2)
			for cell in bedCells:
				addCell(cell)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	floor = ProceduralFurniture.new([Vector2i(0, 0)], "Floor", floorMesh)
	bed = ProceduralFurniture.new(bedOccupied, "Bed", bedMesh)
	mesh = $MeshInstance3D
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
