extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var viewport : SubViewport = get_node("/root/World/Camera/windowTexture")
	get_surface_override_material(0).set_shader_parameter("windowTexture", viewport.get_texture())
