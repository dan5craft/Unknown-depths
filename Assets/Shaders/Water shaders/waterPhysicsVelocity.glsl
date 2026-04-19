#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer VelocityXMap   { float data[]; } velXMap;
layout(set = 0, binding = 1, std430) restrict buffer VelocityYMap   { float data[]; } velYMap;
layout(set = 0, binding = 2, std430) restrict buffer WaterHeightMap { float data[]; } waterHMap;
layout(set = 0, binding = 3, std430) restrict buffer HeightMap      { float data[]; } hMap;

layout(set = 0, binding = 4) uniform Params {
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
    return getHeight(x, y)+waterHMap.data[x*params.size.y+y];
}

void changeVelX(int x, int y, float value){
    velXMap.data[x*params.size.y+y] = clamp(value, -0.5*(params.dx/params.dt), 0.5*(params.dx/params.dt));
}
void changeVelY(int x, int y, float value){
    velYMap.data[x*(params.size.y+1)+y] = clamp(value, -0.5*(params.dx/params.dt), 0.5*(params.dx/params.dt));
}
void changeWaterHeight(int x, int y, float value){
    waterHMap.data[x*params.size.y+y] = value;
}

void main() {
    int x = int(gl_GlobalInvocationID.x);
    int y = int(gl_GlobalInvocationID.y);
    if(x >= params.size.x || y >= params.size.y) return;
    float dvx = 0.0;
    float dvy = 0.0;
    if(x > 0){
        dvx = -(params.gravity/params.dx)*(getCombinedWaterHeight(x, y)-getCombinedWaterHeight(x-1, y));
    }
    if(y > 0){
        dvy = -(params.gravity/params.dx)*(getCombinedWaterHeight(x, y)-getCombinedWaterHeight(x, y-1));
    }
    changeVelX(x, y, getVelX(x, y)+dvx*params.dt);
    changeVelY(x, y, getVelY(x, y)+dvy*params.dt);
}