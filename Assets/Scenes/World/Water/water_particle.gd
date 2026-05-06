extends RigidBody3D

@export var lifetime:float
var timer := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if(timer > lifetime):
		queue_free()
	pass
