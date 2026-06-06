extends Node3D

var player:PlayerController
@export var command:String = "command"
@export var binded:Node

func interact():
	binded.onButtonPressed(command)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = $"../Tracker".player
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
