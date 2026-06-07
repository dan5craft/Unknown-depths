extends Node3D

var player:PlayerController
@export var command:String = "command"
@export var binded:Node
@export var active:bool = true

var up = true

func interact():
	if $AnimationPlayer.is_playing() or not active:
		return
	$AnimationPlayer.play("buttonPress")
	binded.onButtonPressed(command)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = $"../Tracker".player


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if active == false and up == true:
		up = false
		$AnimationPlayer.play("buttonDeactivate")
	if active == true and up == false:
		up = true
		$AnimationPlayer.play_backwards("buttonDeactivate")
