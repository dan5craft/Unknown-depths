#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer VelocityXMap   { float data[]; } velXMap;
layout(set = 0, binding = 1, std430) restrict buffer VelocityYMap   { float data[]; } velYMap;
layout(set = 0, binding = 2, std430) restrict buffer WaterHeightMap { float data[]; } waterHMap;
layout(set = 0, binding = 3, std430) restrict buffer HeightMap      { float data[]; } hMap;
layout(set = 0, binding = 4, std430) restrict buffer TemporaryMap   { float data[]; } tempMap;

layout(set = 0, binding = 5) uniform Params {
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
    return tempMap.data[x*params.size.y+y];
}
float getHeight(int x, int y){
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
    return hMap.data[x*params.size.y+y];
}

void changeWaterHeight(int x, int y, float value){
    if(value < 0.0){
        value = 0.0;
    }
    waterHMap.data[x*params.size.y+y] = max(value, 0.0);
}

vec4 getUpH(int x, int y){
    vec4 upwindHeight;
    /*
    x = (-1, 0)
    y = (1, 0)
    z = (0, -1)
    w = (0, 1)
    */
    if(getVelX(x, y) > 0.0){
        upwindHeight.x = getWaterHeight(x-1, y);
    } else{
        upwindHeight.x = getWaterHeight(x, y);
    }
    if(getVelX(x+1, y) > 0.0){
        upwindHeight.y = getWaterHeight(x, y);
    } else{
        upwindHeight.y = getWaterHeight(x+1, y);
    }
    if(getVelY(x, y) > 0.0){
        upwindHeight.z = getWaterHeight(x, y-1);
    } else{
        upwindHeight.z = getWaterHeight(x, y);
    }
    if(getVelY(x, y+1) > 0.0){
        upwindHeight.w = getWaterHeight(x, y);
    } else{
        upwindHeight.w = getWaterHeight(x, y+1);
    }
    float hadj = max(0, (upwindHeight.y+upwindHeight.x+upwindHeight.w+upwindHeight.z)/4-2.0*(params.dx/(params.gravity*params.dt)));
    upwindHeight -= hadj;
    return upwindHeight;
}

void main() {
    int x = int(gl_GlobalInvocationID.x);
    int y = int(gl_GlobalInvocationID.y);
    if(x >= params.size.x || y >= params.size.y) return;
    vec4 upH = getUpH(x, y);
    float dh = -((upH.y*getVelX(x+1, y)-upH.x*getVelX(x, y))/params.dx+(upH.w*getVelY(x, y+1)-upH.z*getVelY(x, y))/params.dx);
    changeWaterHeight(x, y, tempMap.data[x*params.size.y+y]+dh*params.dt);
}