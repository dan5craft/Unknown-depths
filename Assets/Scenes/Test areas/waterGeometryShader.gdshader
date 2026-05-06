shader_type spatial;

uniform sampler2D waterHeightmap;
uniform sampler2D heightmap;
uniform sampler2D velXmap;
uniform sampler2D velYmap;
uniform float detail;
uniform float absorptionCoefficient;
uniform float minFoamSpeed = 2.0;
uniform float maxFoamSpeed = 5.0;
uniform vec3 waterColor;
uniform sampler2D depthTexture:hint_depth_texture;
uniform sampler2D screenTexture;

varying float whf;

render_mode cull_disabled;
render_mode depth_draw_always;

float getCombinedHeight(vec2 height, float wh){
	return wh+height.y;
}

bool isEdge(ivec2 texelCoords){
	ivec2 size = textureSize(waterHeightmap, 0);
	ivec2 Rtc = ivec2(min(texelCoords.x+1, size.x-1), texelCoords.y);
	ivec2 Btc = ivec2(texelCoords.x, min(texelCoords.y+1, size.y-1));
	ivec2 Ltc = ivec2(max(texelCoords.x-1, 0), texelCoords.y);
	ivec2 Ttc = ivec2(texelCoords.x, max(texelCoords.y-1, 0));
	ivec2 D1tc = ivec2(Rtc.x, Ttc.y);
	ivec2 D2tc = ivec2(Ltc.x, Btc.y);
	float Rwh = texelFetch(waterHeightmap, Rtc, 0).r;
	float Bwh = texelFetch(waterHeightmap, Btc, 0).r;
	float Lwh = texelFetch(waterHeightmap, Ltc, 0).r;
	float Twh = texelFetch(waterHeightmap, Ttc, 0).r;
	float D1wh = texelFetch(waterHeightmap, D1tc, 0).r;
	float D2wh = texelFetch(waterHeightmap, D2tc, 0).r;
	if(Rwh < 0.001 || Bwh < 0.001 || Lwh < 0.001 || Twh < 0.001 || D1wh < 0.001 || D2wh < 0.001){
		return true;
	} else{
		return false;
	}
}

void vertex() {
	ivec2 size = textureSize(waterHeightmap, 0);
	ivec2 texelCoords = ivec2(int(round(UV.x*float(size.x-1))), int(round(UV.y*float(size.y-1))));
	float wh = texelFetch(waterHeightmap, texelCoords, 0).x;
	vec2 h = texelFetch(heightmap, texelCoords, 0).xy;
	float cwh = h.y+wh;
	//vec2 xTexel = 1.0 / vec2(textureSize(velXmap, 0));
	//vec2 yTexel = 1.0 / vec2(textureSize(velYmap, 0));
	//float vX1 = sqrt(pow(texture(velXmap, UV).r, 2.0));
	//float vX2 = sqrt(pow(texture(velXmap, vec2(UV.x+xTexel.x, UV.y)).r, 2.0));
	//float vY1 = sqrt(pow(texture(velXmap, UV).r, 2.0));
	//float vY2 = sqrt(pow(texture(velXmap, vec2(UV.x, UV.y+yTexel.y)).r, 2.0));
	//float v = (vX1 + vX2 + vY1 + vY2)/4.0;
	//float foamHeight = 0.0;
	//if(v >= minFoamSpeed){
		//foamHeight = 0.5*(v-minFoamSpeed)/(maxFoamSpeed-minFoamSpeed);
	//}
	ivec2 Rtc = ivec2(min(texelCoords.x+1, size.x-1), texelCoords.y);
	ivec2 Btc = ivec2(texelCoords.x, min(texelCoords.y+1, size.y-1));
	ivec2 Ltc = ivec2(max(texelCoords.x-1, 0), texelCoords.y);
	ivec2 Ttc = ivec2(texelCoords.x, max(texelCoords.y-1, 0));
	ivec2 D1tc = ivec2(Rtc.x, Ttc.y);
	ivec2 D2tc = ivec2(Ltc.x, Btc.y);
	float Rwh = texelFetch(waterHeightmap, Rtc, 0).r;
	float Bwh = texelFetch(waterHeightmap, Btc, 0).r;
	float Lwh = texelFetch(waterHeightmap, Ltc, 0).r;
	float Twh = texelFetch(waterHeightmap, Ttc, 0).r;
	float D1wh = texelFetch(waterHeightmap, D1tc, 0).r;
	float D2wh = texelFetch(waterHeightmap, D2tc, 0).r;
	vec2 Rh = texelFetch(heightmap, Rtc, 0).xy;
	vec2 Bh = texelFetch(heightmap, Btc, 0).xy;
	vec2 Lh = texelFetch(heightmap, Ltc, 0).xy;
	vec2 Th = texelFetch(heightmap, Ttc, 0).xy;
	vec2 D1h = texelFetch(heightmap, D1tc, 0).xy;
	vec2 D2h = texelFetch(heightmap, D2tc, 0).xy;
	float Rcwh = Rh.y+Rwh;
	float Bcwh = Bh.y+Bwh;
	float Lcwh = Lh.y+Lwh;
	float Tcwh = Th.y+Twh;
	float D1cwh = D1h.y+D1wh;
	float D2cwh = D2h.y+D2wh;
	vec3 R = vec3(detail, Rcwh-cwh, 0.0);
	vec3 B = vec3(0.0, Bcwh-cwh, detail);
	vec3 L = vec3(-detail, Lcwh-cwh, 0.0);
	vec3 T = vec3(0.0, Tcwh-cwh, -detail);
	vec3 RB = cross(B, R);
	vec3 LT = cross(T, L);
	if(texelCoords.x > 0 && texelCoords.y > 0 && texelCoords.x < size.x-1 && texelCoords.y < size.y-1 && Rh.y > 0.0 && Bh.y > 0.0 && Lh.y > 0.0 && Th.y > 0.0){
		NORMAL = normalize(RB+LT);
	}
	if(wh < 0.01){
		float highest = 0.0;
		float highestW = 0.0;
		vec2 mult = vec2(0.0);
		if(Rwh > highestW){
			highestW = Rwh;
			highest = Rcwh;
			mult = vec2(1.0, 0.0);
		}
		if(Bwh > highestW){
			highestW = Bwh;
			highest = Bcwh;
			mult = vec2(0.0, 1.0);
		}
		if(Lwh > highestW){
			highestW = Lwh;
			highest = Lcwh;
			mult = vec2(-1.0, 0.0);
		}
		if(Twh > highestW){
			highestW = Twh;
			highest = Tcwh;
			mult = vec2(0.0, -1.0);
		}
		/*if(D1wh > highestW){
			highestW = D1wh;
			highest = D1cwh;
			mult = vec2(1.0/sqrt(2.0), -1.0/sqrt(2.0));
		}
		if(D2wh > highestW){
			highestW = D2wh;
			highest = D2cwh;
			mult = vec2(-1.0/sqrt(2.0), 1.0/sqrt(2.0));
		}*/
		float v = atan(detail/h.y);
		float l = h.y-highest;
		float d = tan(v)*l;
		cwh = highest;
		VERTEX.xz = UV*vec2(size)*vec2(detail)-vec2(size)*vec2(detail)*0.5+d*mult*2.0;
		NORMAL = vec3(0.0, 1.0, 0.0);
		whf = 0.0;
	}else{
		VERTEX.xz = UV*vec2(size)*vec2(detail)-vec2(size)*vec2(detail)*0.5;
		whf = wh;
	}
	VERTEX.y = cwh;//+foamHeight;
}

vec3 lerp_color(vec3 color1, vec3 color2, float p){
	p = clamp(p, 0.0, 1.0);
    return color1+(color2-color1)*p;
}

void fragment() {
	ivec2 size = textureSize(waterHeightmap, 0);
	ivec2 texelCoords = ivec2(int(round(UV.x*float(size.x-1))), int(round(UV.y*float(size.y-1))));
	//vec2 texel = 1.0 / vec2(textureSize(waterHeightmap, 0));
	float wh = texelFetch(waterHeightmap, texelCoords, 0).x;
	vec2 h = texelFetch(heightmap, texelCoords, 0).xy;
	//vec2 h = texture(heightmap, UV, 0).xy;
	float cwh = h.y+wh;
	vec2 xTexel = 1.0 / vec2(textureSize(velXmap, 0));
	vec2 yTexel = 1.0 / vec2(textureSize(velYmap, 0));
	float vX1 = sqrt(pow(texture(velXmap, UV).r, 2.0));
	float vX2 = sqrt(pow(texture(velXmap, vec2(UV.x+xTexel.x, UV.y)).r, 2.0));
	float vY1 = sqrt(pow(texture(velXmap, UV).r, 2.0));
	float vY2 = sqrt(pow(texture(velXmap, vec2(UV.x, UV.y+yTexel.y)).r, 2.0));
	float v = (vX1 + vX2 + vY1 + vY2)/4.0;
	float foamPercent = clamp((v-minFoamSpeed)/(maxFoamSpeed-minFoamSpeed), 0.0, 1.0);
	if(whf < (h.x-h.y)/2.0){
		ALPHA = clamp(whf/0.05, 0.0, 1.0);
	}else{
		ALPHA = clamp((h.x-whf-h.y)/0.1, 0.0, 1.0);
	}
	ivec2 Rtc = ivec2(min(texelCoords.x+1, size.x-1), texelCoords.y);
	ivec2 Btc = ivec2(texelCoords.x, min(texelCoords.y+1, size.y-1));
	ivec2 Ltc = ivec2(max(texelCoords.x-1, 0), texelCoords.y);
	ivec2 Ttc = ivec2(texelCoords.x, max(texelCoords.y-1, 0));
	ivec2 D1tc = ivec2(Rtc.x, Ttc.y);
	ivec2 D2tc = ivec2(Ltc.x, Btc.y);
	float Rwh = texelFetch(waterHeightmap, Rtc, 0).r;
	float Bwh = texelFetch(waterHeightmap, Btc, 0).r;
	float Lwh = texelFetch(waterHeightmap, Ltc, 0).r;
	float Twh = texelFetch(waterHeightmap, Ttc, 0).r;
	float D1wh = texelFetch(waterHeightmap, D1tc, 0).r;
	float D2wh = texelFetch(waterHeightmap, D2tc, 0).r;
	vec2 Rh = texelFetch(heightmap, Rtc, 0).xy;
	vec2 Bh = texelFetch(heightmap, Btc, 0).xy;
	vec2 Lh = texelFetch(heightmap, Ltc, 0).xy;
	vec2 Th = texelFetch(heightmap, Ttc, 0).xy;
	vec2 D1h = texelFetch(heightmap, D1tc, 0).xy;
	vec2 D2h = texelFetch(heightmap, D2tc, 0).xy;
	/*vec2 RtcF = vec2(UV.x+texel.x, UV.y);
	vec2 BtcF = vec2(UV.x, UV.y+texel.y);
	vec2 LtcF = vec2(UV.x-texel.x, UV.y);
	vec2 TtcF = vec2(UV.x, UV.y-texel.y);
	vec2 D1tcF = vec2(RtcF.x, TtcF.y);
	vec2 D2tcF = vec2(LtcF.x, BtcF.y);
	float Rwh = texture(waterHeightmap, RtcF).r;
	float Bwh = texture(waterHeightmap, BtcF).r;
	float Lwh = texture(waterHeightmap, LtcF).r;
	float Twh = texture(waterHeightmap, TtcF).r;
	float D1wh = texture(waterHeightmap, D1tcF).r;
	float D2wh = texture(waterHeightmap, D2tcF).r;
	vec2 Rh = texture(heightmap, RtcF).xy;
	vec2 Bh = texture(heightmap, BtcF).xy;
	vec2 Lh = texture(heightmap, LtcF).xy;
	vec2 Th = texture(heightmap, TtcF).xy;
	vec2 D1h = texture(heightmap, D1tcF).xy;
	vec2 D2h = texture(heightmap, D2tcF).xy;*/
	float Rcwh = Rh.y+Rwh;
	float Bcwh = Bh.y+Bwh;
	float Lcwh = Lh.y+Lwh;
	float Tcwh = Th.y+Twh;
	float D1cwh = D1h.y+D1wh;
	float D2cwh = D2h.y+D2wh;
	/*if(Rcwh < h.y || Bcwh < h.y || Lcwh < h.y || Tcwh < h.y || D1cwh < h.y || D2cwh < h.y){
		ALPHA = 0.0;
	}*/
	/*if(Rh.y == 0.0 || Bh.y == 0.0 || Lh.y == 0.0 || Th.y == 0.0 || D1h.y == 0.0 || D2h.y == 0.0){
		ALPHA = 0.0;
	}*/
	/*if(
	Rh.y == 0.0 && UV.x*float(size.x-1)-round(UV.x*float(size.x-1))+0.5 > 0.5||
	Bh.y == 0.0 && UV.y*float(size.x-1)-round(UV.y*float(size.y-1))+0.5 > 0.5||
	Lh.y == 0.0 && UV.x*float(size.x-1)-round(UV.x*float(size.x-1))+0.5 < 0.5||
	Th.y == 0.0 && UV.y*float(size.x-1)-round(UV.y*float(size.y-1))+0.5 < 0.5||
	D1h.y == 0.0 && UV.x*float(size.x-1)-round(UV.x*float(size.x-1))+0.5 > 0.5 && UV.y*float(size.x-1)-round(UV.y*float(size.y-1))+0.5 < 0.5||
	D2h.y == 0.0 && UV.x*float(size.x-1)-round(UV.x*float(size.x-1))+0.5 < 0.5 && UV.y*float(size.x-1)-round(UV.y*float(size.y-1))+0.5 > 0.5){
		ALPHA = 0.0;
	}
	if(
	Rwh < 0.0005 && UV.x*float(size.x-1)-floor(UV.x*float(size.x-1)) > 0.5||
	Bwh < 0.0005 && UV.y*float(size.y-1)-floor(UV.y*float(size.y-1)) > 0.5||
	Lwh < 0.0005 && UV.x*float(size.x-1)-floor(UV.x*float(size.x-1)) < 0.5||
	Twh < 0.0005 && UV.y*float(size.y-1)-floor(UV.y*float(size.y-1)) < 0.5||
	D1wh < 0.0005 && UV.x*float(size.x-1)-floor(UV.x*float(size.x-1)) > 0.5 && UV.y*float(size.y-1)-floor(UV.y*float(size.y-1)) < 0.5||
	D2wh < 0.0005 && UV.x*float(size.x-1)-floor(UV.x*float(size.x-1)) < 0.5 && UV.y*float(size.y-1)-floor(UV.y*float(size.y-1)) > 0.5){
		ALPHA = 0.0;
	}*/
	/*float Rp = UV.x*float(size.x-1)-round(UV.x*float(size.x-1))+0.5;
	float Rrh = Rp*(((Rh.y-h.y)*0.5+h.y)-h.y)+h.y;
	float Bp = UV.y*float(size.y-1)-round(UV.y*float(size.y-1))+0.5;
	float Brh = Bp*(((Bh.y-h.y)*0.5+h.y)-h.y)+h.y;
	float Lp = 1.0-UV.x*float(size.x-1)+round(UV.x*float(size.x-1))-0.5;
	float Lrh = Lp*(((Lh.y-h.y)*0.5+h.y)-h.y)+h.y;
	float Tp = 1.0-UV.y*float(size.y-1)+round(UV.y*float(size.y-1))-0.5;
	float Trh = Tp*(((Th.y-h.y)*0.5+h.y)-h.y)+h.y;
	float D1p = 1.0-UV.y*float(size.y-1)+round(UV.x*float(size.y-1))-0.5;
	float D1rh = Tp*(Th.y-h.y);
	float D2p = 1.0-UV.y*float(size.y-1)+round(UV.x*float(size.y-1))-0.5;
	float D2rh = Tp*(Th.y-h.y);
	if(cwh < Rrh){
		ALPHA = 0.0;
	}
	if(cwh < Brh){
		ALPHA = 0.0;
	}
	if(cwh < Lrh){
		ALPHA = 0.0;
	}
	if(cwh < Trh){
		ALPHA = 0.0;
	}*/
	ROUGHNESS = 0.1;//+foamPercent*0.9;
	SPECULAR = 0.2;
	CLEARCOAT = 1.0;
	CLEARCOAT_ROUGHNESS = 0.1;
	float depth;
	if(FRONT_FACING){
		depth = texture(depthTexture, SCREEN_UV).r;
		depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
		depth += VERTEX.z;
	} else{
		depth = 0.0;
	}
	float absorption = exp(-absorptionCoefficient*depth);
	vec3 screenColor = pow(texture(screenTexture, SCREEN_UV).rgb, vec3(2.2));
	vec3 color = lerp_color(waterColor*screenColor, screenColor, absorption)*absorption+waterColor*0.05*(1.0-absorption);
	//ALBEDO = lerp_color(waterColor*screenColor, screenColor, absorption)*absorption;
	if(v >= minFoamSpeed){
		ALBEDO = lerp_color(color, vec3(1.0), foamPercent);
		//ALBEDO = color;
	} else{
		ALBEDO = color;
	}
	//ALBEDO = vec3(pixelPos.y-pixelH);
}

float DistributionGGX(float cos_theta_m, float alpha)
{
	float alpha2 = alpha * alpha;
	float d = 1.0 + (alpha2 - 1.0) * cos_theta_m * cos_theta_m;
	return alpha2 / (PI * d * d);
}

float GeometryGGX(float NdotL, float NdotV, float alpha)
{
	return 0.5 / mix(2.0 * NdotL * NdotV, NdotL + NdotV, alpha);
}

vec3 SchlickBaseReflectivity(float metallic, float specular, vec3 albedo)
{
	float dielectric = 0.04 * specular * specular;
	return mix(vec3(dielectric), albedo, vec3(metallic));
}
	
float SchlickFresnel(float u)
{
	float m = 1.0 - u;
	float m2 = m * m;
	return m2 * m2 * m;
}

void light()
{
	// Calculate some vectors.
	vec3 lightColor = LIGHT_COLOR / PI;
	
	vec3 half = normalize(VIEW + LIGHT);

	vec3 lightN = NORMAL;
    if (dot( lightN, LIGHT ) < 0.0)
    {
        // reverse the normal if it's facing away from the light
        lightN = -1.0 * lightN;
    }
	
	float NdotL = max(dot(lightN, LIGHT), 0.0);
	float NdotV = max(dot(lightN, VIEW), 0.0);
	float NdotH = max(dot(lightN, half), 0.0);
	float LdotH = max(dot(lightN, half), 0.0);
	
	// Diffuse light (Lambert).
	DIFFUSE_LIGHT += clamp(dot(lightN, LIGHT), 0.0, 1.0) * ATTENUATION * lightColor;
	
	// Specular light (Schlick-GGX).
	float ggxAlpha = ROUGHNESS * ROUGHNESS;
	float D = DistributionGGX(NdotH, ggxAlpha);
	float G = GeometryGGX(NdotL, NdotV, ggxAlpha);
	
	vec3 f0 = SchlickBaseReflectivity(METALLIC, SPECULAR_AMOUNT, ALBEDO);
	float LdotH5 = SchlickFresnel(LdotH);
	float f90 = clamp(50.0 * f0.g, 0.0, 1.0);
	vec3 F = f0 + (f90 - f0) * LdotH5;
	
	vec3 specularBRDF = max(NdotL * D * G * F, 0.0);
	SPECULAR_LIGHT += specularBRDF * LIGHT_COLOR * ATTENUATION;
}