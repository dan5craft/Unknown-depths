@tool
extends SubViewport

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var screenSize = DisplayServer.screen_get_size()
	size = screenSize
