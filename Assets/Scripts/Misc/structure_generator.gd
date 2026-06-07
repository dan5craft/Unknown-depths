extends Node3D

@export var generateFurnitureButton:Node3D
@export var button2:Node3D

var cells:Array[genCell] = []
var rng = RandomNumberGenerator.new()

func findCell(pos:Vector2i):
	var x:int = pos.x
	var y:int = pos.y
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

func onButtonPressed(command:String):
	if command == "generate furniture":
		generateFurnitureButton.active = false
		for i in range(100000):
			var x = floor(float(i)/100.0)
			var y = i % 100
			#var x:int = rng.randi_range(0, 10)
			#var y:int = rng.randi_range(0, 10)
			var cell:genCell = genCell.new(Vector2i(x, y))
			addCell(cell)
		button2.active = true
		for cell in cells:
			print(cell.pos)
	if command.begins_with("find"):
		var pos = command.erase(0, 4).remove_chars(" ").split(",")
		var x = int(pos[0])
		var y = int(pos[1])
		var cell = findCell(Vector2i(x, y))
		if cell:
			print(cell.pos)
		else:
			print("could not find cell on position X: "+str(x)+" Y: "+str(y))



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
