extends Node3D
@export var detail : float = 4:
	set(value):
		detail = value
@export var framerate : int = 60:
	set(value):
		framerate = value
@export var gravity : float = 9.8:
	set(value):
		gravity = value
@export var size : Vector2i = Vector2(10, 10):
	set(value):
		size = value
		_createMaps()

var rd : RenderingDevice
var height_shader : RID
var velocity_shader : RID
var velocityXMap
var velocityYMap
var waterHeightMap
var heightMap
var tempMap

func _ready() -> void:
	rd = RenderingServer.create_local_rendering_device()
	var shader_file := load("res://Assets/Shaders/Water shaders/waterPhysicsHeight.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	height_shader = rd.shader_create_from_spirv(shader_spirv)
	shader_file = load("res://Assets/Shaders/Water shaders/waterPhysicsVelocity.glsl")
	shader_spirv = shader_file.get_spirv()
	velocity_shader = rd.shader_create_from_spirv(shader_spirv)
	if velocityXMap == null:
		_createMaps()

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

func _process(delta: float) -> void:
	pass

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
	
	var paramArray := PackedFloat32Array([size.x, size.y, gravity, detail, 1.0/framerate, 0.0, 0.0, 0.0])
	var paramBytes := paramArray.to_byte_array()
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
	compute_list = rd.compute_list_begin()  # new list!
	rd.compute_list_bind_compute_pipeline(compute_list, pipelineVelocity)
	rd.compute_list_bind_uniform_set(compute_list, mapsUniformSetVelocity, 0)
	rd.compute_list_dispatch(compute_list, (size.x+7)/8, (size.y+7)/8, 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()
	var output_bytes := rd.buffer_get_data(velXMapBuffer)
	var output := output_bytes.to_float32_array()
	var outputString := ""
	for y in range(size.y):
		for x in range(size.x+1):
			outputString += str(output[x*(size.y)+y])+" "
		outputString += "\n"
	print(outputString)
	output_bytes = rd.buffer_get_data(paramBuffer)
	output = output_bytes.to_float32_array()
	print(output)
