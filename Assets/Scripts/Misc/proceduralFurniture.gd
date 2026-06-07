class_name ProceduralFurniture

@export var occupied:Array[Vector2i]
@export var name:String
@export var mesh:Mesh

func _init(OCCUPIED:Array[Vector2i], NAME:String, MESH:Mesh) -> void:
	occupied = OCCUPIED
	name = NAME
	mesh = MESH

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
