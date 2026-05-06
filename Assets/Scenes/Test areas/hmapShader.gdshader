shader_type spatial;

uniform sampler2D heightmap;
uniform vec3 color;
uniform float detail;
uniform float maxHeight;
uniform float minHeight;

render_mode depth_draw_always;

void vertex() {
	ivec2 size = textureSize(heightmap, 0);
	ivec2 texelCoords = ivec2(int(round(UV.x*float(size.x-1))), int(round(UV.y*float(size.y-1))));
	float h = texelFetch(heightmap, texelCoords, 0).x;
	VERTEX.y = h;
	ivec2 Rtc = ivec2(min(texelCoords.x+1, size.x-1), texelCoords.y);
	ivec2 Btc = ivec2(texelCoords.x, min(texelCoords.y+1, size.y-1));
	ivec2 Ltc = ivec2(max(texelCoords.x-1, 0), texelCoords.y);
	ivec2 Ttc = ivec2(texelCoords.x, max(texelCoords.y-1, 0));
	float Rh = texelFetch(heightmap, Rtc, 0).x;
	float Bh = texelFetch(heightmap, Btc, 0).x;
	float Lh = texelFetch(heightmap, Ltc, 0).x;
	float Th = texelFetch(heightmap, Ttc, 0).x;
	vec3 R = vec3(detail, Rh-h, 0.0);
	vec3 B = vec3(0.0, Bh-h, detail);
	vec3 L = vec3(-detail, Lh-h, 0.0);
	vec3 T = vec3(0.0, Th-h, -detail);
	vec3 RB = cross(B, R);
	vec3 LT = cross(T, L);
	if(texelCoords.x > 0 && texelCoords.y > 0 && texelCoords.x < size.x-1 && texelCoords.y < size.y-1){
		NORMAL = normalize(RB+LT);
	}
	// Called for every vertex the material is visible on.
}

void fragment() {
	ivec2 size = textureSize(heightmap, 0);
	ivec2 texelCoords = ivec2(int(round(UV.x*float(size.x-1))), int(round(UV.y*float(size.y-1))));
	float h = texelFetch(heightmap, texelCoords, 0).x;
	ivec2 Rtc = ivec2(min(texelCoords.x+1, size.x-1), texelCoords.y);
	ivec2 Btc = ivec2(texelCoords.x, min(texelCoords.y+1, size.y-1));
	ivec2 Ltc = ivec2(max(texelCoords.x-1, 0), texelCoords.y);
	ivec2 Ttc = ivec2(texelCoords.x, max(texelCoords.y-1, 0));
	ivec2 D1tc = ivec2(Rtc.x, Ttc.y);
	ivec2 D2tc = ivec2(Ltc.x, Btc.y);
	float Rh = texelFetch(heightmap, Rtc, 0).x;
	float Bh = texelFetch(heightmap, Btc, 0).x;
	float Lh = texelFetch(heightmap, Ltc, 0).x;
	float Th = texelFetch(heightmap, Ttc, 0).x;
	float D1h = texelFetch(heightmap, D1tc, 0).x;
	float D2h = texelFetch(heightmap, D2tc, 0).x;
	if(h == minHeight || h == maxHeight){
		ALPHA = 0.0;
	}
	if(Rh == minHeight || Rh == maxHeight || Bh == minHeight || Bh == maxHeight || Lh == minHeight || Lh == maxHeight || Th == minHeight || Th == maxHeight || D1h == minHeight || D1h == maxHeight || D2h == minHeight || D2h == maxHeight){
		ALPHA = 0.0;
	}
	ALBEDO = color;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
