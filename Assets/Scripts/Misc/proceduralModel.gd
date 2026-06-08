class_name ProceduralModel

@export var occupied:Array[Vector2i]
@export var name:String
@export var mesh:Mesh
@export var pos:Vector3
@export var rot:int
@export var center:Vector2

func _init(OCCUPIED:Array[Vector2i], NAME:String, MESH:Mesh, POS:Vector3, ROT:int, CENTER:Vector2) -> void:
	occupied = OCCUPIED
	name = NAME
	mesh = MESH
	pos = POS
	rot = ROT
	center = CENTER

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
