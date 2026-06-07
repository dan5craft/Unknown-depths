class_name genCell

@export var pos:Vector2i = Vector2i.ZERO
@export var type:String = "Empty"
@export var models:Array[Mesh]

func _init(x:int, y:int, TYPE:String, MODELS:Array[Mesh]) -> void:
	pos = Vector2i(x, y)
	type = TYPE
	models = MODELS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
