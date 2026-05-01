@tool
extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = false
		$"../MeshInstance3D".visible = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		mesh.size.x = $"..".gridSize.x
		mesh.size.y = $"..".gridSize.y
	pass
