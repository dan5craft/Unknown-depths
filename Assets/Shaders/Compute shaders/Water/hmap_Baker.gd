@tool
extends Node3D

@export_tool_button("Bake Heightmaps", "Bake") var bakeButton = bakeButtonFunc

var maxHeightMap = []
var minHeightMap = []
var heightTexture:ImageTexture

func bakeButtonFunc():
	bakeHeightMaps()
	var detail:float = $"..".detail
	var gridSize:Vector2 = $"..".gridSize
	var size:Vector2i = gridSize/detail
	var maxHeight:float = $"..".maxHeight
	var minHeight:float = $"..".minHeight
	var hmapPlane := PlaneMesh.new()
	hmapPlane.size = size*detail
	hmapPlane.subdivide_width = size.x-2
	hmapPlane.subdivide_depth = size.y-2
	$BottomHmap.mesh = hmapPlane
	var hmapPlane2 = hmapPlane.duplicate()
	hmapPlane2.set_flip_faces(true)
	$TopHmap.mesh = hmapPlane2
	var topHeightImage = Image.create(size.x, size.y, 0, Image.FORMAT_RF)
	var bottomHeightImage = Image.create(size.x, size.y, 0, Image.FORMAT_RF)
	for x in range(size.x):
		for y in range(size.y):
			topHeightImage.set_pixel(x, y, Color(maxHeightMap[x*size.y+y], 0.0, 0.0, 0.0))
			bottomHeightImage.set_pixel(x, y, Color(minHeightMap[x*size.y+y], 0.0, 0.0, 0.0))
	var topHeightTexture = ImageTexture.create_from_image(topHeightImage)
	var bottomHeightTexture = ImageTexture.create_from_image(bottomHeightImage)
	$TopHmap.get_surface_override_material(0).set_shader_parameter("heightmap", topHeightTexture)
	$BottomHmap.get_surface_override_material(0).set_shader_parameter("heightmap", bottomHeightTexture)
	$TopHmap.get_surface_override_material(0).set_shader_parameter("detail", detail)
	$BottomHmap.get_surface_override_material(0).set_shader_parameter("detail", detail)
	$TopHmap.get_surface_override_material(0).set_shader_parameter("minHeight", minHeight)
	$BottomHmap.get_surface_override_material(0).set_shader_parameter("minHeight", minHeight)
	$TopHmap.get_surface_override_material(0).set_shader_parameter("maxHeight", maxHeight)
	$BottomHmap.get_surface_override_material(0).set_shader_parameter("maxHeight", maxHeight)

func castRay(x, y, h1, h2) -> Dictionary:
	var detail:float = $"..".detail
	var gridSize:Vector2 = $"..".gridSize
	var space_state = get_world_3d().direct_space_state
	var gridCorner:Vector2 = Vector2(global_position.x - gridSize.x/2.0, global_position.z - gridSize.y/2.0)
	#var start:Vector3 = Vector3(gridCorner.x+x*detail+detail*0.5, global_position.y+h1, gridCorner.y+y*detail+detail*0.5)
	#var end:Vector3 = Vector3(gridCorner.x+x*detail+detail*0.5, global_position.y+h2, gridCorner.y+y*detail+detail*0.5)
	var offset:float = sqrt(2*pow(detail, 2.0))/2.0;
	var start:Vector3 = Vector3(gridCorner.x+x*detail+offset, global_position.y+h1, gridCorner.y+y*detail+offset)
	var end:Vector3 = Vector3(gridCorner.x+x*detail+offset, global_position.y+h2, gridCorner.y+y*detail+offset)
	var query := PhysicsRayQueryParameters3D.create(start, end)
	return space_state.intersect_ray(query)

func bakeHeightMaps():
	var detail:float = $"..".detail
	var gridSize:Vector2 = $"..".gridSize
	var size:Vector2i = gridSize/detail
	var maxHeight:float = $"..".maxHeight
	var minHeight:float = $"..".minHeight
	var heighestHeight = 0.0
	var space_state = get_world_3d().direct_space_state
	var gridCorner:Vector2 = Vector2(global_position.x - gridSize.x/2.0, global_position.z - gridSize.y/2.0)
	var heightImage = Image.create(size.x, size.y, 0, Image.FORMAT_RGBAF)
	maxHeightMap = []
	minHeightMap = []
	for x in range(size.x*size.y):
		maxHeightMap.append(0.0)
		minHeightMap.append(0.0)
	for x in range(size.x):
		for y in range(size.y):
			var heightColor := Color(0.0, 0.0, 0.0, 1.0)
			var result := castRay(x, y, maxHeight, minHeight)
			if result:
				var h:float = result.position.y-global_position.y
				if h > heighestHeight:
					heighestHeight = h
				heightColor.r = h
				maxHeightMap[x*size.y+y] = h
			else:
				heightColor.r = maxHeight
				maxHeightMap[x*size.y+y] = maxHeight
			result = castRay(x, y, minHeight, maxHeight)
			if result:
				var h:float = result.position.y-global_position.y
				heightColor.g = h
				minHeightMap[x*size.y+y] = h
			else:
				heightColor.g = minHeight
				minHeightMap[x*size.y+y] = minHeight
			heightImage.set_pixel(x, y, heightColor)
	print("The maximum height found was "+str(heighestHeight))
	heightTexture = ImageTexture.create_from_image(heightImage)
