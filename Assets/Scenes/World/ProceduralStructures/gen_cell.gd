class_name genCell extends Node3D

@export var pos:Vector2i = Vector2i.ZERO
@export var type:String = "Empty"
@export var models:Array[Node3D]

func _init(POS:Vector2i) -> void:
	pos = POS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for model in models:
		add_child(model)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
