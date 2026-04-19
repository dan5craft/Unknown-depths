#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;

layout(set = 0, binding = 1, std430) restrict buffer AvgColor {
    uint b;
    uint scale;
    ivec2 raster_size;
} avgColor;


// The code we want to execute in each invocation
void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = avgColor.raster_size;

    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    vec3 color = imageLoad(color_image, uv).rgb;
    if(color.r > color.g && color.r > color.b){
        atomicAdd(avgColor.b, int(color.r*float(avgColor.scale)));
    } else if(color.g > color.r && color.g > color.b){
        atomicAdd(avgColor.b, int(color.g*float(avgColor.scale)));
    } else{
        atomicAdd(avgColor.b, int(color.b*float(avgColor.scale)));
    }
}