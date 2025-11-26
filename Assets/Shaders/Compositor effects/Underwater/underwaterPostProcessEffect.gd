@tool
extends CompositorEffect
class_name UnderwaterEffect

var rd: RenderingDevice
var shader: RID
var blurShader: RID
var pipeline: RID
var blurPipeline: RID
var nearest_sampler: RID
var linear_sampler: RID
var context : StringName = "underwaterEffects"
var imageContainerName : StringName = "image_container"

@export var water_color : Color = Color(0.0, 0.0, 1.0)
@export var water_absorption : float = 0.2
@export var blurRadius : float = 2.0
@export var blurStepAmount : int = 10
@export var blurCircleAmount : int = 3

# Called when this resource is constructed.
func _init():
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	rd = RenderingServer.get_rendering_device()
	var shader_file: RDShaderFile = load("res://Assets/Shaders/Compositor effects/Underwater/underwaterShader.glsl")
	var shader_spirv = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	shader_file = load("res://Assets/Shaders/Compositor effects/Underwater/underwaterBlur.glsl")
	shader_spirv = shader_file.get_spirv()
	blurShader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	blurPipeline = rd.compute_pipeline_create(blurShader)
	var sampler_state := RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	nearest_sampler = RenderingServer.get_rendering_device().sampler_create(sampler_state)
	sampler_state = RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	linear_sampler = rd.sampler_create(sampler_state)

# System notifications, we want to react on the notification that
# alerts us we are about to be destroyed.
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if shader.is_valid():
			# Freeing our shader will also free any dependents such as the pipeline!
			rd.free_rid(shader)
		if nearest_sampler.is_valid():
			rd.free_rid(nearest_sampler)
		if linear_sampler.is_valid():
			rd.free_rid(linear_sampler)

# Called by the rendering thread every frame.
func _render_callback(p_effect_callback_type, p_render_data):
	if rd and p_effect_callback_type == EFFECT_CALLBACK_TYPE_POST_TRANSPARENT and shader.is_valid():
		# Get our render scene buffers object, this gives us access to our render buffers.
		# Note that implementation differs per renderer hence the need for the cast.
		var render_scene_buffers: RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()
		var render_scene_data: RenderSceneDataRD = p_render_data.get_render_scene_data()
		if render_scene_buffers:
			# Get our render size, this is the 3D render resolution!
			var size = render_scene_buffers.get_internal_size()
			if size.x == 0 and size.y == 0:
				return
			if !render_scene_buffers.has_texture(context, imageContainerName):
				var usage_bits : int = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
				render_scene_buffers.create_texture(context, imageContainerName, RenderingDevice.DATA_FORMAT_R16G16B16A16_UNORM, usage_bits, RenderingDevice.TEXTURE_SAMPLES_1, size, 1, 0, true, false)
			# We can use a compute shader here.
			var x_groups = (size.x - 1) / 8 + 1
			var y_groups = (size.y - 1) / 8 + 1
			var z_groups = 1
			# Push constant.
			var params = [
				size.x,
				size.y,
				0.0,
				0.0,
				water_color.r,
				water_color.g,
				water_color.b,
				water_absorption
			]
			var pba = PackedByteArray()
			pba.append_array(PackedFloat32Array(params).to_byte_array())
			var params_buffer: RID = rd.uniform_buffer_create(pba.size(), pba)
			var params_uniform: RDUniform = RDUniform.new()
			params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
			params_uniform.binding = 0
			params_uniform.add_id(params_buffer)
			var params_uniform_set: RID = UniformSetCacheRD.get_cache(shader, 4, [params_uniform])

			# Loop through views just in case we're doing stereo rendering. No extra cost if this is mono.
			var view_count = render_scene_buffers.get_view_count()
			for view in range(view_count):
				rd.draw_command_begin_label("My own shit", Color(1.0, 0.0, 0.0, 1.0))
				var view_projection = render_scene_data.get_view_projection(view)
				
				var projection_matrix = [
					view_projection.x.x, view_projection.x.y, view_projection.x.z, view_projection.x.w, 
					view_projection.y.x, view_projection.y.y, view_projection.y.z, view_projection.y.w, 
					view_projection.z.x, view_projection.z.y, view_projection.z.z, view_projection.z.w, 
					view_projection.w.x, view_projection.w.y, view_projection.w.z, view_projection.w.w, 
				]
				var pma =  PackedFloat32Array(projection_matrix).to_byte_array()
				var pb = PackedByteArray()
				pb.append_array(pma)
				
				var matrix_buffer : RID =  rd.uniform_buffer_create(64, pb)
				var matrices_uniform : RDUniform = RDUniform.new()
				matrices_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
				matrices_uniform.binding = 0
				matrices_uniform.add_id(matrix_buffer)
				var matrices_uniform_set: RID = UniformSetCacheRD.get_cache(shader, 3, [matrices_uniform])
				
				# Get the RID for our color image, we will be reading from and writing to it.
				var input_image = render_scene_buffers.get_color_layer(view)
				var depth_image = render_scene_buffers.get_depth_layer(view)
				var image_container = render_scene_buffers.get_texture_slice(context, imageContainerName, view, 0, 1, 1)
				# Create a uniform set.
				# This will be cached; the cache will be cleared if our viewport's configuration is changed.
				var color_uniform: RDUniform = RDUniform.new()
				color_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
				color_uniform.binding = 0
				color_uniform.add_id(input_image)
				var image_container_uniform: RDUniform = RDUniform.new()
				image_container_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
				image_container_uniform.binding = 0
				image_container_uniform.add_id(image_container)
				var depth_uniform: RDUniform = RDUniform.new()
				depth_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				depth_uniform.binding = 0
				depth_uniform.add_id(linear_sampler)
				depth_uniform.add_id(depth_image)
				var color_uniform_set = UniformSetCacheRD.get_cache(shader, 0, [color_uniform])
				var image_container_uniform_set = UniformSetCacheRD.get_cache(shader, 1, [image_container_uniform])
				var depth_uniform_set = UniformSetCacheRD.get_cache(shader, 2, [depth_uniform])

				# Run our compute shader.
				var compute_list:= rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
				rd.compute_list_bind_uniform_set(compute_list, color_uniform_set, 0)
				rd.compute_list_bind_uniform_set(compute_list, image_container_uniform_set, 1)
				rd.compute_list_bind_uniform_set(compute_list, depth_uniform_set, 2)
				rd.compute_list_bind_uniform_set(compute_list, matrices_uniform_set, 3)
				rd.compute_list_bind_uniform_set(compute_list, params_uniform_set, 4)
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
				rd.compute_list_end()
				params = [
					size.x,
					size.y,
					0.0,
					0.0,
					water_color.r,
					water_color.g,
					water_color.b,
					water_absorption,
					blurRadius,
					blurStepAmount,
					blurCircleAmount,
					0
				]
				pba = PackedByteArray()
				pba.append_array(PackedFloat32Array(params).to_byte_array())
				params_buffer = rd.uniform_buffer_create(pba.size(), pba)
				params_uniform = RDUniform.new()
				params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
				params_uniform.binding = 0
				params_uniform.add_id(params_buffer)
				image_container_uniform = RDUniform.new()
				image_container_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
				image_container_uniform.binding = 0
				image_container_uniform.add_id(image_container)
				params_uniform_set = UniformSetCacheRD.get_cache(blurShader, 4, [params_uniform])
				matrices_uniform_set = UniformSetCacheRD.get_cache(blurShader, 3, [matrices_uniform])
				color_uniform_set = UniformSetCacheRD.get_cache(blurShader, 0, [color_uniform])
				image_container_uniform_set = UniformSetCacheRD.get_cache(blurShader, 1, [image_container_uniform])
				depth_uniform_set = UniformSetCacheRD.get_cache(blurShader, 2, [depth_uniform])
				compute_list = rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, blurPipeline)
				rd.compute_list_bind_uniform_set(compute_list, color_uniform_set, 0)
				rd.compute_list_bind_uniform_set(compute_list, image_container_uniform_set, 1)
				rd.compute_list_bind_uniform_set(compute_list, depth_uniform_set, 2)
				rd.compute_list_bind_uniform_set(compute_list, matrices_uniform_set, 3)
				rd.compute_list_bind_uniform_set(compute_list, params_uniform_set, 4)
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
				rd.compute_list_end()
				if params_buffer.is_valid():
					rd.free_rid(params_buffer)
				if matrix_buffer.is_valid():
					rd.free_rid(matrix_buffer) 
