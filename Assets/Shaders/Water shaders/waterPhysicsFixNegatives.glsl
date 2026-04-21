#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer WaterHeightMap { float data[]; } waterHMap;
layout(set = 0, binding = 1, std430) restrict buffer TemporaryMap   { float data[]; } tempMap;
layout(set = 0, binding = 2, std430) restrict buffer OutputParams   { bool hasNegative; } outputParams;

layout(set = 0, binding = 3) uniform Params {
    ivec2 size;
    float gravity;
    float dx;
    float dt;
} params;

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

void addWater(int x, int y, float value){
    waterHMap.data[x*params.size.y+y] += value;
    if(waterHMap.data[x*params.size.y+y] < 0.0){
        outputParams.hasNegative = true;
    }
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
    float sum = 0.0;
    ivec2[4] neighbours;
    float[4] heights;
    float lowest = 0.0;
    bool allNegative = true;
    if(x>0){
        float nh = getWaterHeight(x-1, y);
        if(nh<0.0){
            if(nh < lowest){lowest = nh;}
        }else{allNegative = false;}
        neighbours[n] = ivec2(x-1, y);
        heights[n] = nh;
        sum += nh;
        n+=1;
    }
    if(x<params.size.x-1){
        float nh = getWaterHeight(x+1, y);
        if(nh<0.0){
            if(nh < lowest){lowest = nh;}
        }else{allNegative = false;}
        neighbours[n] = ivec2(x+1, y);
        heights[n] = nh;
        sum += nh;
        n+=1;
    }
    if(y>0){
        float nh = getWaterHeight(x, y-1);
        if(nh<0.0){
            if(nh < lowest){lowest = nh;}
        }else{allNegative = false;}
        neighbours[n] = ivec2(x, y-1);
        heights[n] = nh;
        sum += nh;
        n+=1;
    }
    if(y<params.size.y-1){
        float nh = getWaterHeight(x, y+1);
        if(nh<0.0){
            if(nh < lowest){lowest = nh;}
        }else{allNegative = false;}
        neighbours[n] = ivec2(x, y+1);
        heights[n] = nh;
        sum += nh;
        n+=1;
    }
    sum -= lowest*n;
    float movedAmount = -h;//min(sum, -h);
    for(int i=0;i<n;i++){
        float p;
        if(sum>0.0 && allNegative == false){
            p = (heights[i]-lowest)/sum;
        } else{
            //changeWater(x, y, 0.0);
            return;
        }
        addWater(neighbours[i].x, neighbours[i].y, -movedAmount*p);
    }
    addWater(x, y, movedAmount);
}