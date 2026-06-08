class_name genCell

var pos:Vector2i = Vector2i.ZERO
var type:String = "Empty"
var models:Array[ProceduralModel]

func _init(x:int, y:int, TYPE:String, MODELS:Array[ProceduralModel]) -> void:
	pos = Vector2i(x, y)
	type = TYPE
	models = MODELS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
