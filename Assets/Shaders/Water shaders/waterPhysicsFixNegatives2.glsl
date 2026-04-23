#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) buffer WaterHeightMap { float data[]; } waterHMap;
layout(set = 0, binding = 1, std430) readonly buffer DiffMap   { float data[]; } diffMap;
layout(set = 0, binding = 2, std430) writeonly buffer OutputParams   { bool hasNegative; } outputParams;

layout(set = 0, binding = 3) uniform Params {
    ivec2 size;
    float gravity;
    float dx;
    float dt;
} params;

float getWaterHeight(int x, int y){
    return waterHMap.data[x*params.size.y+y];
}

void addWater(int x, int y, float value){
    waterHMap.data[x*params.size.y+y] += value;
    if(waterHMap.data[x*params.size.y+y] < -1.0){
        outputParams.hasNegative = true;
    }
}

void changeWater(int x, int y, float value){
    waterHMap.data[x*params.size.y+y] = value;
}

float getDiff(int x, int y){
    return diffMap.data[x*params.size.y+y];
}

void main() {
    int x = int(gl_GlobalInvocationID.x);
    int y = int(gl_GlobalInvocationID.y);
    if(x >= params.size.x || y >= params.size.y) return;
    float d = getDiff(x, y);
    if(d<0.0){return;}
    int n = 0;
    ivec2[4] neighbors;
    if(x>0){
        neighbors[n] = ivec2(x-1, y);
        n++;
    }
    if(x<params.size.x-1){
        neighbors[n] = ivec2(x+1, y);
        n++;
    }
    if(y>0){
        neighbors[n] = ivec2(x, y-1);
        n++;
    }
    if(y<params.size.y-1){
        neighbors[n] = ivec2(x, y+1);
        n++;
    }
    for(int i=0;i<n;i++){
        ivec2 pos = neighbors[i];
        addWater(x, y, getDiff(pos.x, pos.y));
    }
}