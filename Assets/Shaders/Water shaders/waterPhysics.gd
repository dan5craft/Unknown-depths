extends Node3D
@export var detail : float = 4:
	set(value):
		detail = value
@export var framerate : int = 60:
	set(value):
		framerate = value
@export var timeScale : int = 2;
@export var gravity : float = 9.8:
	set(value):
		gravity = value
@export var size : Vector2i = Vector2(10, 10):
	set(value):
		size = value
		_createMaps()
@export var maxTerrainHeight = 2.0;

var rd : RenderingDevice
var height_shader : RID
var velocity_shader : RID
var velocityXMap
var velocityYMap
var waterHeightMap
var heightMap
var tempMap
var timer = 0.0
var texture : ImageTexture
var image : Image
var rng = RandomNumberGenerator.new()

func getWaterHeight(x : int, y : int) -> float:
	return waterHeightMap[x*size.y+y]

func isUnderwater(pos : Vector3) -> bool:
	var diff := Vector2(pos.x-(position.x-size.x*detail/2.0), pos.z-(position.z-size.y*detail/2.0))
	var x : int = round(diff.x/detail)-1
	var y : int = round(diff.y/detail)-1
	if x < 0.0 or x > size.x-1 or y < 0.0 or y > size.y-1:
		return false
	if(getWaterHeight(x, y)+position.y >= pos.y):
		return true
	else:
		return false

func _ready() -> void:
	#get_viewport().debug_draw = Viewport.DEBUG_DRAW_NORMAL_BUFFER
	#get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	size = size/detail;
	rd = RenderingServer.create_local_rendering_device()
	var shader_file := load("res://Assets/Shaders/Water shaders/waterPhysicsHeight.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	height_shader = rd.shader_create_from_spirv(shader_spirv)
	shader_file = load("res://Assets/Shaders/Water shaders/waterPhysicsVelocity.glsl")
	shader_spirv = shader_file.get_spirv()
	velocity_shader = rd.shader_create_from_spirv(shader_spirv)
	if velocityXMap == null:
		_createMaps()
	var waterSurface := PlaneMesh.new()
	waterSurface.size = size*detail
	waterSurface.subdivide_width = size.x-2
	waterSurface.subdivide_depth = size.y-2
	$MeshInstance3D.mesh = waterSurface
	#var r : int = rng.randi_range(0, size.x*size.y-1)
	#waterHeightMap[r] -= 1.0
	$MeshInstance3D.get_surface_override_material(0).set_shader_parameter("detail", detail)
	image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBF)
	texture = ImageTexture.create_from_image(image)
	#for x in range(100):
		#var r : int = rng.randi_range(0, size.x*size.y-1)
		#waterHeightMap[r] += 1.0/pow(detail, 2.0)
	#waterHeightMap[size.x/2*size.y+size.y/2] += 1000.0

func _createMaps():
	velocityXMap = []
	velocityYMap = []
	waterHeightMap = []
	heightMap = []
	for x in range(size.y):
		velocityXMap.append(0.0)
		velocityYMap.append(0.0)
		for y in range(size.x):
			velocityXMap.append(0.0)
			velocityYMap.append(0.0)
			waterHeightMap.append(0.0)
			heightMap.append(0.0)

func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			for x in range(100):
				var r : int = rng.randi_range(0, size.x*size.y-1)
				waterHeightMap[r] += 1.0/pow(detail, 2.0)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			for x in range(100):
				var r : int = rng.randi_range(0, size.x*size.y-1)
				waterHeightMap[r] -= 1.0/pow(detail, 2.0)*10.0

func _process(delta: float) -> void:
	#position.y += 0.01;
	#$"../SubViewport/Camera3D".position.y += 0.01;
	#$"../Camera3D2".position.y += 0.01;
	#$"../OmniLight3D2".position.y += 0.01;
	timer += delta
	if timer < 1.0/framerate:
		return
	#for x in range(20000):
		#var r : int = rng.randi_range(0, size.x*size.y-1)
		#waterHeightMap[r] += 0.00001/pow(detail, 2.0)
	#waterHeightMap[size.x/2*size.y+size.y/2] += 0.01/pow(detail, 2.0)
	timer = 0.0
	for x in range(timeScale):
		iteratePhysics()
	for x in range(size.x):
		for y in range(size.y):
			var h : float = waterHeightMap[x*size.y+y]
			#var vx : float = velocityYMap[x*(size.y+1)+y]/5
			image.set_pixel(x, y, Color(h, h, h))
	texture.update(image)
	$MeshInstance3D.get_surface_override_material(0).set_shader_parameter("heightmap", texture)
	$Control/TextureRect.texture = texture

func iteratePhysics():
	var velXMapArray := PackedFloat32Array(velocityXMap)
	var velXMapBytes := velXMapArray.to_byte_array()
	var velXMapBuffer := rd.storage_buffer_create(velXMapBytes.size(), velXMapBytes)
	var velXMapUniform := RDUniform.new()
	velXMapUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	velXMapUniform.binding = 0
	velXMapUniform.add_id(velXMapBuffer)
	
	var velYMapArray := PackedFloat32Array(velocityYMap)
	var velYMapBytes := velYMapArray.to_byte_array()
	var velYMapBuffer := rd.storage_buffer_create(velYMapBytes.size(), velYMapBytes)
	var velYMapUniform := RDUniform.new()
	velYMapUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	velYMapUniform.binding = 1
	velYMapUniform.add_id(velYMapBuffer)
	
	var waterHMapArray := PackedFloat32Array(waterHeightMap)
	var waterHMapBytes := waterHMapArray.to_byte_array()
	var waterHMapBuffer := rd.storage_buffer_create(waterHMapBytes.size(), waterHMapBytes)
	var waterHMapUniform := RDUniform.new()
	waterHMapUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	waterHMapUniform.binding = 2
	waterHMapUniform.add_id(waterHMapBuffer)
	
	var hMapArray := PackedFloat32Array(heightMap)
	var hMapBytes := hMapArray.to_byte_array()
	var hMapBuffer := rd.storage_buffer_create(hMapBytes.size(), hMapBytes)
	var hMapUniform := RDUniform.new()
	hMapUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	hMapUniform.binding = 3
	hMapUniform.add_id(hMapBuffer)
	
	var tempMapArray := PackedFloat32Array(waterHeightMap)
	var tempMapBytes := tempMapArray.to_byte_array()
	var tempMapBuffer := rd.storage_buffer_create(tempMapBytes.size(), tempMapBytes)
	var tempMapUniform := RDUniform.new()
	tempMapUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	tempMapUniform.binding = 4
	tempMapUniform.add_id(tempMapBuffer)
	
	var paramArray := PackedInt32Array([int(size.x), int(size.y)])
	var paramBytes := paramArray.to_byte_array()
	paramBytes.append_array(PackedFloat32Array([gravity, detail, 1.0/framerate*timeScale, 0.0, 0.0, 0.0]).to_byte_array())
	var paramBuffer := rd.uniform_buffer_create(paramBytes.size(), paramBytes)
	var paramUniform := RDUniform.new()
	paramUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	paramUniform.binding = 5
	paramUniform.add_id(paramBuffer)
	
	var mapsUniformSetHeight := rd.uniform_set_create([velXMapUniform, velYMapUniform, waterHMapUniform, hMapUniform, tempMapUniform, paramUniform], height_shader, 0)
	
	var pipelineHeight := rd.compute_pipeline_create(height_shader)
	var pipelineVelocity := rd.compute_pipeline_create(velocity_shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipelineHeight)
	rd.compute_list_bind_uniform_set(compute_list, mapsUniformSetHeight, 0)
	rd.compute_list_dispatch(compute_list, (size.x+7)/8, (size.y+7)/8, 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()
	
	paramUniform.binding = 4
	var mapsUniformSetVelocity := rd.uniform_set_create([velXMapUniform, velYMapUniform, waterHMapUniform, hMapUniform, paramUniform], velocity_shader, 0)
	mapsUniformSetVelocity.get_id()
	compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipelineVelocity)
	rd.compute_list_bind_uniform_set(compute_list, mapsUniformSetVelocity, 0)
	rd.compute_list_dispatch(compute_list, (size.x+7)/8, (size.y+7)/8, 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()
	
	var output_bytes := rd.buffer_get_data(velXMapBuffer)
	var output := output_bytes.to_float32_array()
	velocityXMap = output
	output_bytes = rd.buffer_get_data(velYMapBuffer)
	output = output_bytes.to_float32_array()
	velocityYMap = output
	output_bytes = rd.buffer_get_data(waterHMapBuffer)
	output = output_bytes.to_float32_array()
	waterHeightMap = output
	output_bytes = rd.buffer_get_data(hMapBuffer)
	output = output_bytes.to_float32_array()
	heightMap = output
	rd.free_rid(pipelineHeight)
	rd.free_rid(pipelineVelocity)
	rd.free_rid(mapsUniformSetHeight)
	rd.free_rid(mapsUniformSetVelocity)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		rd.free_rid(height_shader)
		rd.free_rid(velocity_shader)
