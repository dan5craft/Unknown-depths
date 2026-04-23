#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) buffer WaterHeightMap { float data[]; } waterHMap;
layout(set = 0, binding = 1, std430) readonly buffer TempMap   { float data[]; } tempMap;
layout(set = 0, binding = 2, std430) writeonly buffer DiffMap   { float data[]; } diffMap;

layout(set = 0, binding = 3) uniform Params {
    ivec2 size;
    float gravity;
    float dx;
    float dt;
} params;

float getWaterHeight(int x, int y){
    return tempMap.data[x*params.size.y+y];
}

void addWater(int x, int y, float value){
    waterHMap.data[x*params.size.y+y] += value;
}

void changeDiff(int x, int y, float value){
    diffMap.data[x*params.size.y+y] = value;
}

void changeWater(int x, int y, float value){
    waterHMap.data[x*params.size.y+y] = value;
}

void main() {
    int x = int(gl_GlobalInvocationID.x);
    int y = int(gl_GlobalInvocationID.y);
    if(x >= params.size.x || y >= params.size.y) return;
    float h = getWaterHeight(x, y);
    if(h>=0.0){return;}
    int n = 0;
    if(x>0 && getWaterHeight(x-1, y) >= 0.0){
        n++;
    }
    if(x<params.size.x-1 && getWaterHeight(x+1, y) >= 0.0){
        n++;
    }
    if(y>0 && getWaterHeight(x, y-1) >= 0.0){
        n++;
    }
    if(y<params.size.y-1 && getWaterHeight(x, y+1) >= 0.0){
        n++;
    }
    if(n>0){
        changeDiff(x, y, h/n);
        changeWater(x, y, 0.0);
    }
}