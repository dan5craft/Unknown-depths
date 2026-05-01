#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer VelocityXMap   { float data[]; } velXMap;
layout(set = 0, binding = 1, std430) restrict buffer VelocityYMap   { float data[]; } velYMap;
layout(set = 0, binding = 2, std430) restrict buffer WaterHeightMap { float data[]; } waterHMap;
layout(set = 0, binding = 3, std430) restrict buffer HeightMap      { float data[]; } hMap;
layout(set = 0, binding = 4, r32f) uniform image2D velXTexture;
layout(set = 0, binding = 5, r32f) uniform image2D velYTexture;

layout(set = 0, binding = 6) uniform Params {
    ivec2 size;
    float gravity;
    float dx;
    float dt;
} params;

float getVelX(int x, int y){
    return velXMap.data[x*params.size.y+y];
}
float getVelY(int x, int y){
    return velYMap.data[x*(params.size.y+1)+y];
}
float getWaterHeight(int x, int y){
    if(x >= params.size.x){
        x = params.size.x-1;
    } else if(x < 0){
        x = 0;
    }
    if(y >= params.size.y){
        y = params.size.y-1;
    } else if(y < 0){
        y = 0;
    }
    return waterHMap.data[x*params.size.y+y];
}
vec2 getHeight(int x, int y){
    /*
    x = max height
    y = min height
    */
    if(x >= params.size.x){
        x = params.size.x-1;
    } else if(x < 0){
        x = 0;
    }
    if(y >= params.size.y){
        y = params.size.y-1;
    } else if(y < 0){
        y = 0;
    }
    int arraySize = params.size.x*params.size.y;
    float maxH = hMap.data[x*params.size.y+y];
    float minH = hMap.data[x*params.size.y+y+arraySize];
    return vec2(maxH, minH);
}
float getCombinedWaterHeight(int x, int y){
    if(x >= params.size.x){
        x = params.size.x-1;
    } else if(x < 0){
        x = 0;
    }
    if(y >= params.size.y){
        y = params.size.y-1;
    } else if(y < 0){
        y = 0;
    }
    vec2 height = getHeight(x, y);
    float wh = getWaterHeight(x, y);
    return wh+height.y;
}

void changeVelX(int x, int y, float value){
    float wh1 = getWaterHeight(x-1, y);
    float wh2 = getWaterHeight(x, y);
    vec2 h1 = getHeight(x-1, y);
    vec2 h2 = getHeight(x, y);
    float cwh1 = getCombinedWaterHeight(x-1, y);
    float cwh2 = getCombinedWaterHeight(x, y);
    value = clamp(value, -(h1.x-cwh1)/wh2*0.25*(params.dx/params.dt), (h2.x-cwh2)/wh1*0.25*(params.dx/params.dt));
    value = clamp(value, -0.25*(params.dx/params.dt), 0.25*(params.dx/params.dt));
    velXMap.data[x*params.size.y+y] = value;
    imageStore(velXTexture, ivec2(x, y), vec4(value));
}
void changeVelY(int x, int y, float value){
    float wh1 = getWaterHeight(x, y-1);
    float wh2 = getWaterHeight(x, y);
    vec2 h1 = getHeight(x, y-1);
    vec2 h2 = getHeight(x, y);
    float cwh1 = getCombinedWaterHeight(x, y-1);
    float cwh2 = getCombinedWaterHeight(x, y);
    value = clamp(value, -(h1.x-cwh1)/wh2*0.25*(params.dx/params.dt), (h2.x-cwh2)/wh1*0.25*(params.dx/params.dt));
    value = clamp(value, -0.25*(params.dx/params.dt), 0.25*(params.dx/params.dt));
    velYMap.data[x*(params.size.y+1)+y] = value;
    imageStore(velYTexture, ivec2(x, y), vec4(value));
}

void main() {
    int x = int(gl_GlobalInvocationID.x);
    int y = int(gl_GlobalInvocationID.y);
    if(x >= params.size.x || y >= params.size.y) return;
    float dvx = 0.0;
    float dvy = 0.0;
    if(x > 0){
        float wh1 = getWaterHeight(x-1, y);
        float wh2 = getWaterHeight(x, y);
        vec2 h1 = getHeight(x-1, y);
        vec2 h2 = getHeight(x, y);
        if(wh1+wh2 < 0.01 || h1.y == 0 || h2.y == 0){
            changeVelX(x, y, 0.0);
        } else{
            float cwh1 = getCombinedWaterHeight(x-1, y);
            float cwh2 = getCombinedWaterHeight(x, y);
            dvx = (-params.gravity/params.dx)*(cwh1-cwh2)*params.dt;
            changeVelX(x, y, getVelX(x, y)/(1.0+0.25*params.dt)+dvx);
        }
    }
    if(y > 0){
        float wh1 = getWaterHeight(x, y-1);
        float wh2 = getWaterHeight(x, y);
        vec2 h1 = getHeight(x, y-1);
        vec2 h2 = getHeight(x, y);
        if(wh1+wh2 < 0.01 || h1.y == 0 || h2.y == 0){
            changeVelY(x, y, 0.0);
        } else{
            float cwh1 = getCombinedWaterHeight(x, y-1);
            float cwh2 = getCombinedWaterHeight(x, y);
            dvy = (-params.gravity/params.dx)*(cwh1-cwh2)*params.dt;
            changeVelY(x, y, getVelY(x, y)/(1.0+0.25*params.dt)+dvy);
        }
    }
}