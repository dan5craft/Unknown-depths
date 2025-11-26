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
    vec4 blurParams;
} params;

vec3 lerp_color(vec3 color1, vec3 color2, float p){
    return color1+(color2-color1)*p;
}

const float PI = 3.1415926535897932384626433832795;

// The code we want to execute in each invocation
void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = params.raster_size;

    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    float water_absorption = params.water_color.w;
    float blurRadius = params.blurParams.x;
    int blurStepAmount = int(params.blurParams.y);
    int blurCircleAmount = int(params.blurParams.z);
    if (blurStepAmount <= 0 || blurCircleAmount <= 0) {
        return;
    }

    float depth_raw = texelFetch(depth_image, uv, 0).r;
    vec3 ndc = vec3((uv * 2.0) - 1.0, depth_raw);
    vec4 view = inverse(mat.proj) * vec4(ndc, 1.0);
    float depth = -(view.xyz / view.w).z;

    float absorption = exp(-water_absorption*depth);

    vec3 color = imageLoad(image_container, uv).rgb;
    int skips = 0;
    for(int circle=1;circle<=blurCircleAmount;circle++){
        for(int circleStep=0;circleStep<blurStepAmount*circle;circleStep++){
            float angle = 2*PI/(blurStepAmount*circle)*circleStep;
            ivec2 pixel = ivec2(round(cos(angle)*blurRadius*circle*(1.0-absorption))+uv.x, round(sin(angle)*blurRadius*circle*(1.0-absorption))+uv.y);
            if (pixel.x >= size.x || pixel.x < 0 || pixel.y >= size.y || pixel.y < 0) {
                skips += 1;
                continue;
            }
            vec3 pixelColor = imageLoad(image_container, pixel).rgb;
            color += pixelColor;
        }
    }
    color = color/(blurCircleAmount*blurStepAmount+1-skips);

    imageStore(color_image, uv, vec4(color, 1.0));
}