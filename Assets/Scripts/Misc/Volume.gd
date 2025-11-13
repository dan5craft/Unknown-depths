@tool
extends Area3D
@export var volume : float = 0.0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if volume == 0.0 and self.get_child_count() > 0:
		var children := self.get_children()
		for child in children:
			if child.get_class() == "CollisionShape3D":
				var shape = child.shape;
				volume += shape.size.x*shape.size.y*shape.size.z;
	pass
