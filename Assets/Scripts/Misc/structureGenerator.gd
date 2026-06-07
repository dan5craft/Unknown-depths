extends Node3D

@export var generateFurnitureButton:Node3D
@export var button2:Node3D
@export var floor:PackedScene
@export var bed:PackedScene

var cells:Array[genCell] = []
var rng = RandomNumberGenerator.new()

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
		cell.position = Vector3(x, 0.0, y)
		add_child(cell)
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
	cell.position = Vector3(x, 0.0, y)
	add_child(cell)

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
			print(cell.pos)
		else:
			print("could not find cell on position X: "+str(x)+" Y: "+str(y))

func generateFurnitureCells(furniture:ProceduralFurniture, x:int, y:int):
	var furnitureCells = []
	for pos in furniture.occupied:
		var floorInstance = floor.instantiate()
		var models = [floorInstance]
		if pos == Vector2i.ZERO:
			models.append(furniture)
		var cell:genCell = genCell.new(pos.x+x, pos.y+y, "Furniture", models)
		furnitureCells.append(cell)
	return furnitureCells

func generateFurniture():
	for x in range(100):
		for y in range(50):
			var bedInstance:ProceduralFurniture = bed.instantiate()
			var bedCells = generateFurnitureCells(bedInstance, x, y*2)
			for cell in bedCells:
				addCell(cell)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
