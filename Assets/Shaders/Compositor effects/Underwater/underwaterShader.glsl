#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;

layout(rgba16f, set = 1, binding = 0) uniform image2D image_container;

layout(set = 2, binding = 0) uniform sampler2D depth_image;

layout(set = 3, binding=0) uniform uniformBuffer {
    mat4 proj;
} mat;

layout(set = 4, binding=0) uniform Params {
    ivec2 raster_size;
    vec4 water_color;
} params;

vec3 lerp_color(vec3 color1, vec3 color2, float p){
    return color1+(color2-color1)*p;
}

// The code we want to execute in each invocation
void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = params.raster_size;

    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    vec3 color = imageLoad(color_image, uv).rgb;
    vec3 water_color = params.water_color.rgb;
    float water_absorption = params.water_color.w;

    float depth_raw = texelFetch(depth_image, uv, 0).r;
    vec3 ndc = vec3((uv * 2.0) - 1.0, depth_raw);
    vec4 view = inverse(mat.proj) * vec4(ndc, 1.0);
    float depth = -(view.xyz / view.w).z;

    float absorption = exp(-water_absorption*depth);
    color = lerp_color(water_color*color, color, absorption)*absorption;

    imageStore(image_container, uv, vec4(color, 1.0));
}