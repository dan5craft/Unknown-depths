extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var viewport : SubViewport = get_node("/root/World/Setup/Camera/noFilter")
	get_surface_override_material(0).set_shader_parameter("screenTexture", viewport.get_texture())
