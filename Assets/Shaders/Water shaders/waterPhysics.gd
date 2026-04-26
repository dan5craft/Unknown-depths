extends Node3D
@export_category("Water properties")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var detail : float = 0.2:
	set(value):
		detail = value
@export var framerate : int = 288:
	set(value):
		framerate = value
@export var timeScale : int = 2;
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s²") var gravity : float = -9.8:
	set(value):
		gravity = value
var size : Vector2i
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var gridSize : Vector2i = Vector2(10, 10):
	set(value):
		gridSize = value
		size = value/detail
		_createMaps()
@export_category("Height map")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var maxTerrainHeight = 2.0;

var rd : RenderingDevice
var height_shader : RID
var velocity_shader : RID
var negative_shader : RID
var negative_shader2 : RID
var velocityXMap
var velocityYMap
var waterHeightMap
var heightMap
var tempMap
var emptyMap
var waterHeightTextureBuffer : RID
var velocityXTextureBuffer : RID
var velocityYTextureBuffer : RID
var timer = 0.0
var waterHeightTexture : Texture2DRD
var heightTexture : ImageTexture
var velXTexture : Texture2DRD
var velYTexture : Texture2DRD
var rng = RandomNumberGenerator.new()

func bakeHeightMaps():
	var heighestHeight = 0.0
	var space_state = get_world_3d().direct_space_state
	var gridCorner:Vector2 = Vector2(global_position.x - gridSize.x/2.0, global_position.z - gridSize.y/2.0)
	var heightImage = Image.create(size.x, size.y, 0, Image.FORMAT_RF)
	for x in range(size.x):
		for y in range(size.y):
			var start:Vector3 = Vector3(gridCorner.x+x*detail+detail/2, global_position.y+maxTerrainHeight, gridCorner.y+y*detail+detail/2)
			var end:Vector3 = Vector3(gridCorner.x+x*detail+detail/2, global_position.y, gridCorner.y+y*detail+detail/2)
			var query = PhysicsRayQueryParameters3D.create(start, end)
			var result = space_state.intersect_ray(query)
			if result:
				var h:float = result.position.y-global_position.y
				if h > heighestHeight:
					heighestHeight = h
				heightImage.set_pixel(x, y, Color(h, 0.0, 0.0))
				heightMap[x*size.y+y] = h
			else:
				heightImage.set_pixel(x, y, Color(0.0, 0.0, 0.0))
				heightMap[x*size.y+y] = 0.0
	#print("The maximum height found was "+str(heighestHeight))
	heightTexture = ImageTexture.create_from_image(heightImage)
	#$Control/TextureRect.texture = heightTexture

func getWaterHeight(x : int, y : int) -> float:
	return waterHeightMap[x*size.y+y]

func isUnderwater(pos : Vector3) -> bool:
	var diff := Vector2(pos.x-(global_position.x-size.x*detail/2.0), pos.z-(global_position.z-size.y*detail/2.0))
	var x : int = round(diff.x/detail)-1
	var y : int = round(diff.y/detail)-1
	if x < 0.0 or x > size.x-1 or y < 0.0 or y > size.y-1:
		return false
	if(getWaterHeight(x, y)+global_position.y+heightMap[x*size.y+y] >= pos.y):
		return true
	else:
		return false

func getVolume():
	var volume := 0.0
	for y in range(size.x*size.y):
		volume += waterHeightMap[y]*pow(detail, 2.0)
	return volume

func setWaterHeight(x:int, y:int, volume:float):
	waterHeightMap[x*size.y+y] = volume

func addWater(x:int, y:int, volume:float):
	waterHeightMap[x*size.y+y] += volume/pow(detail, 2.0)

func addWaterArea(x:int, y:int, volume:float, area:float):
	var cellAmount:int= round(area/pow(detail, 2.0))
	var waterAmount:float = volume/pow(detail, 2.0)/cellAmount
	var radius:float = sqrt(area/PI)
	var cells = []
	while cellAmount > 0:
		for X in range(radius*2):
			for Y in range(radius*2):
				var pos = Vector2i(x-radius+X, y-radius+Y)
				if pos.x < 0 or pos.x > size.x-1 or pos.y < 0 or pos.y > size.y-1 or sqrt(pow(pos.x-x, 2.0)+pow(pos.y-y, 2.0)) > radius or cells.count(pos) > 0:
					continue
				waterHeightMap[pos.x*size.y+pos.y] += waterAmount
				cells.append(pos)
				#print("Added water to cell at X: "+str(pos.x)+" Y: "+str(pos.y))
				cellAmount -= 1
		radius += 1

func printMap(map):
	var mapString := ""
	for y in range(size.y):
		for x in range(size.x):
			var h = str(round(map[x*size.y+y]*1000000.0)/1000000.0)
			mapString += h
			var spaces = 12-len(h)
			for s in range(spaces):
				mapString += " "
		mapString += "\n"
	print(mapString)

func _ready() -> void:
	#get_viewport().debug_draw = Viewport.DEBUG_DRAW_NORMAL_BUFFER
	#get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	size = gridSize/detail
	rd = RenderingServer.get_rendering_device()
	var shader_file := load("res://Assets/Shaders/Water shaders/waterPhysicsHeight.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	height_shader = rd.shader_create_from_spirv(shader_spirv)
	shader_file = load("res://Assets/Shaders/Water shaders/waterPhysicsVelocity.glsl")
	shader_spirv = shader_file.get_spirv()
	velocity_shader = rd.shader_create_from_spirv(shader_spirv)
	shader_file = load("res://Assets/Shaders/Water shaders/waterPhysicsFixNegatives.glsl")
	shader_spirv = shader_file.get_spirv()
	negative_shader = rd.shader_create_from_spirv(shader_spirv)
	shader_file = load("res://Assets/Shaders/Water shaders/waterPhysicsFixNegatives2.glsl")
	shader_spirv = shader_file.get_spirv()
	negative_shader2 = rd.shader_create_from_spirv(shader_spirv)
	if velocityXMap == null:
		_createMaps()
	bakeHeightMaps()
	var texFormat := RDTextureFormat.new()
	texFormat.width = size.x
	texFormat.height = size.y
	texFormat.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	texFormat.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	)
	var emptyBytes := PackedFloat32Array(waterHeightMap).to_byte_array()
	waterHeightTextureBuffer = rd.texture_create(texFormat, RDTextureView.new(), [emptyBytes])
	waterHeightTexture = Texture2DRD.new()
	waterHeightTexture.set_texture_rd_rid(waterHeightTextureBuffer)
	texFormat.width = size.x+1
	emptyBytes = PackedFloat32Array(velocityXMap).to_byte_array()
	velocityXTextureBuffer = rd.texture_create(texFormat, RDTextureView.new(), [emptyBytes])
	velXTexture = Texture2DRD.new()
	velXTexture.set_texture_rd_rid(velocityXTextureBuffer)
	texFormat.width = size.x
	texFormat.height = size.y+1
	emptyBytes = PackedFloat32Array(velocityYMap).to_byte_array()
	velocityYTextureBuffer = rd.texture_create(texFormat, RDTextureView.new(), [emptyBytes])
	velYTexture = Texture2DRD.new()
	velYTexture.set_texture_rd_rid(velocityYTextureBuffer)
	var waterSurface := PlaneMesh.new()
	waterSurface.size = size*detail
	waterSurface.subdivide_width = size.x-2
	waterSurface.subdivide_depth = size.y-2
	$MeshInstance3D.mesh = waterSurface
	#var r : int = rng.randi_range(0, size.x*size.y-1)
	#waterHeightMap[r] -= 1.0
	$MeshInstance3D.get_surface_override_material(0).set_shader_parameter("detail", detail)
	$MeshInstance3D.get_surface_override_material(0).set_shader_parameter("waterColor", Globals.waterColor)
	$MeshInstance3D.get_surface_override_material(0).set_shader_parameter("absorptionCoefficient", Globals.waterAbsorption)
	$MeshInstance3D.get_surface_override_material(0).set_shader_parameter("heightmap", heightTexture)
	#for x in range(100):
		#var r : int = rng.randi_range(0, size.x*size.y-1)
		#waterHeightMap[r] += 1.0/pow(detail, 2.0)
	#addWater(size.x/2-1, size.y/2-1, 200.0)

func _createMaps():
	velocityXMap = []
	velocityYMap = []
	waterHeightMap = []
	heightMap = []
	emptyMap = []
	for x in range(size.y):
		velocityXMap.append(0.0)
		velocityYMap.append(0.0)
		for y in range(size.x):
			velocityXMap.append(0.0)
			velocityYMap.append(0.0)
			waterHeightMap.append(0.0)
			heightMap.append(0.0)
			emptyMap.append(0.0)

func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			for x in range(1):
				var r : int = rng.randi_range(0, size.x*size.y-1)
				addWaterArea(floor(float(r)/size.y), r % size.y, 10000.0, 100.0*pow(detail, 2.0))
		if event.button_index == MOUSE_BUTTON_RIGHT && event.is_pressed():
			for x in range(1):
				var r : int = rng.randi_range(0, size.x*size.y-1)
				addWaterArea(floor(float(r)/size.y), r % size.y, -100.0, 100.0)

func _process(delta: float) -> void:
	#position.y += 0.01;
	#$"../SubViewport/Camera3D".position.y += 0.01;
	#$"../Camera3D2".position.y += 0.01;
	#$"../OmniLight3D2".position.y += 0.01;
	#timer += delta
	#if timer < 1.0/framerate:
		#return
	#for x in range(20000):
		#var r : int = rng.randi_range(0, size.x*size.y-1)
		#waterHeightMap[r] += 0.00001/pow(detail, 2.0)
	#waterHeightMap[size.x/2*size.y+size.y/2] += 0.01/pow(detail, 2.0)
	#timer = 0.0
	#print(getVolume())
	#print(waterHeightMap[50*size.y+50])
	for x in range(timeScale):
		iteratePhysics()
	$MeshInstance3D.get_surface_override_material(0).set_shader_parameter("waterHeightmap", waterHeightTexture)
	$MeshInstance3D.get_surface_override_material(0).set_shader_parameter("velXmap", velXTexture)
	$MeshInstance3D.get_surface_override_material(0).set_shader_parameter("velYmap", velYTexture)

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
	var waterHeightTextureUniform := RDUniform.new()
	waterHeightTextureUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	waterHeightTextureUniform.binding = 5
	waterHeightTextureUniform.add_id(waterHeightTextureBuffer)
	var hasNegative = false;
	var outputArray := PackedInt32Array([hasNegative, 0, 0, 0])
	var outputBytes := outputArray.to_byte_array()
	var outputBuffer := rd.storage_buffer_create(outputBytes.size(), outputBytes)
	var outputUniform := RDUniform.new()
	outputUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	outputUniform.binding = 6
	outputUniform.add_id(outputBuffer)
	var paramArray := PackedInt32Array([int(size.x), int(size.y)])
	var paramBytes := paramArray.to_byte_array()
	paramBytes.append_array(PackedFloat32Array([gravity, detail, 1.0/framerate/timeScale, 0.0, 0.0, 0.0]).to_byte_array())
	var paramBuffer := rd.uniform_buffer_create(paramBytes.size(), paramBytes)
	var paramUniform := RDUniform.new()
	paramUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	paramUniform.binding = 7
	paramUniform.add_id(paramBuffer)
	
	var mapsUniformSetHeight := rd.uniform_set_create([velXMapUniform, velYMapUniform, waterHMapUniform, hMapUniform, tempMapUniform, waterHeightTextureUniform, outputUniform, paramUniform], height_shader, 0)
	
	var pipelineHeight := rd.compute_pipeline_create(height_shader)
	var pipelineVelocity := rd.compute_pipeline_create(velocity_shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipelineHeight)
	rd.compute_list_bind_uniform_set(compute_list, mapsUniformSetHeight, 0)
	rd.compute_list_dispatch(compute_list, (size.x+7)/8, (size.y+7)/8, 1)
	rd.compute_list_add_barrier(compute_list)
	rd.compute_list_end()
	
	if 1 == 2 and rd.buffer_get_data(outputBuffer).to_int32_array()[0] and getVolume() > 1.0:
		var pipelineNegative := rd.compute_pipeline_create(negative_shader)
		var pipelineNegative2 := rd.compute_pipeline_create(negative_shader2)
		var diffMapBytes = PackedFloat32Array(emptyMap).to_byte_array()
		var diffMapBuffer = rd.storage_buffer_create(diffMapBytes.size(), diffMapBytes)
		var diffMapUniform := RDUniform.new()
		diffMapUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		diffMapUniform.binding = 2
		diffMapUniform.add_id(diffMapBuffer)
		tempMapBytes = rd.buffer_get_data(waterHMapBuffer)
		rd.buffer_update(tempMapBuffer, 0, tempMapBytes.size(), tempMapBytes)
		outputBytes = PackedInt32Array([false]).to_byte_array()
		rd.buffer_update(outputBuffer, 0, outputBytes.size(), outputBytes)
		waterHMapUniform.binding = 0
		tempMapUniform.binding = 1
		outputUniform.binding = 2
		paramUniform.binding = 3
		hasNegative = true
		#printMap(waterHeightMap)
		#print(getVolume())
		#printMap(tempMapBytes.to_float32_array())
		var iterations = 0
		compute_list = rd.compute_list_begin()
		while hasNegative:
			iterations += 1
			var uniformSetNegative := rd.uniform_set_create([waterHMapUniform, tempMapUniform, diffMapUniform, paramUniform], negative_shader, 0)
			rd.compute_list_bind_compute_pipeline(compute_list, pipelineNegative)
			rd.compute_list_bind_uniform_set(compute_list, uniformSetNegative, 0)
			rd.compute_list_dispatch(compute_list, (size.x+7)/8, (size.y+7)/8, 1)
			rd.compute_list_add_barrier(compute_list)
			diffMapUniform.binding = 1
			var uniformSetNegative2 := rd.uniform_set_create([waterHMapUniform, diffMapUniform, outputUniform, paramUniform], negative_shader2, 0)
			rd.compute_list_bind_compute_pipeline(compute_list, pipelineNegative2)
			rd.compute_list_bind_uniform_set(compute_list, uniformSetNegative2, 0)
			rd.compute_list_dispatch(compute_list, (size.x+7)/8, (size.y+7)/8, 1)
			rd.compute_list_add_barrier(compute_list)
			tempMapBytes = rd.buffer_get_data(waterHMapBuffer)
			#tempMapArray = tempMapBytes.to_float32_array()
			#var volume := 0.0
			#for y in range(size.x*size.y):
				#volume += tempMapArray[y]*pow(detail, 2.0)
			#print("Negative: "+str(volume))
			#if(volume < 0.15):
				#printMap(rd.buffer_get_data(diffMapBuffer).to_float32_array())
				#printMap(tempMapArray)
			#print("Iteration "+str(iterations)+":")
			#printMap(tempMapArray)
			rd.buffer_update(tempMapBuffer, 0, tempMapBytes.size(), tempMapBytes)
			rd.buffer_update(diffMapBuffer, 0, diffMapBytes.size(), diffMapBytes)
			diffMapUniform.binding = 2
			hasNegative = rd.buffer_get_data(outputBuffer).to_int32_array()[0]
			outputBytes = PackedInt32Array([false]).to_byte_array()
			rd.buffer_update(outputBuffer, 0, outputBytes.size(), outputBytes)
			rd.free_rid(uniformSetNegative)
			rd.free_rid(uniformSetNegative2)
		rd.free_rid(pipelineNegative)
		rd.free_rid(pipelineNegative2)
		rd.free_rid(diffMapBuffer)
		rd.compute_list_end()
	
	waterHMapUniform.binding = 2
	paramUniform.binding = 6
	var velocityXTextureUniform := RDUniform.new()
	velocityXTextureUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	velocityXTextureUniform.binding = 4
	velocityXTextureUniform.add_id(velocityXTextureBuffer)
	var velocityYTextureUniform := RDUniform.new()
	velocityYTextureUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	velocityYTextureUniform.binding = 5
	velocityYTextureUniform.add_id(velocityYTextureBuffer)
	var mapsUniformSetVelocity := rd.uniform_set_create([velXMapUniform, velYMapUniform, waterHMapUniform, hMapUniform, velocityXTextureUniform, velocityYTextureUniform, paramUniform], velocity_shader, 0)
	compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipelineVelocity)
	rd.compute_list_bind_uniform_set(compute_list, mapsUniformSetVelocity, 0)
	rd.compute_list_dispatch(compute_list, (size.x+7)/8, (size.y+7)/8, 1)
	rd.compute_list_end()
	
	var output_bytes = rd.buffer_get_data(velXMapBuffer)
	var output = output_bytes.to_float32_array()
	velocityXMap = output
	output_bytes = rd.buffer_get_data(velYMapBuffer)
	output = output_bytes.to_float32_array()
	velocityYMap = output
	output_bytes = rd.buffer_get_data(hMapBuffer)
	output = output_bytes.to_float32_array()
	heightMap = output
	output_bytes = rd.buffer_get_data(waterHMapBuffer)
	output = output_bytes.to_float32_array()
	waterHeightMap = output
	if pipelineHeight.is_valid():
		rd.free_rid(pipelineHeight)
	if pipelineVelocity.is_valid():
		rd.free_rid(pipelineVelocity)
	if mapsUniformSetHeight.is_valid():
		rd.free_rid(mapsUniformSetHeight)
	if mapsUniformSetVelocity.is_valid():
		rd.free_rid(mapsUniformSetVelocity)
	rd.free_rid(hMapBuffer)
	rd.free_rid(paramBuffer)
	rd.free_rid(tempMapBuffer)
	rd.free_rid(velXMapBuffer)
	rd.free_rid(velYMapBuffer)
	rd.free_rid(waterHMapBuffer)
	rd.free_rid(outputBuffer)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		rd.free_rid(height_shader)
		rd.free_rid(velocity_shader)
		rd.free_rid(negative_shader)
		rd.free_rid(negative_shader2)
		rd.free_rid(velocityXTextureBuffer)
		rd.free_rid(velocityYTextureBuffer)
		rd.free_rid(waterHeightTextureBuffer)
