shader_type spatial;

uniform sampler2D waterHeightmap;
uniform sampler2D heightmap;
uniform sampler2D velXmap;
uniform sampler2D velYmap;
uniform float detail;
uniform float absorptionCoefficient;
uniform float minFoamSpeed = 1.0;
uniform float maxFoamSpeed = 5.0;
uniform vec3 waterColor;
uniform sampler2D depthTexture:hint_depth_texture;
uniform sampler2D screenTexture;

render_mode cull_disabled;
render_mode depth_draw_always;

float getCombinedHeight(vec4 height, float wh){
	if(wh+height.y <= height.w){
        return wh+height.y;
    } else{
        return wh+height.y+(height.z-height.w);
    }
}

void vertex() {
	ivec2 size = textureSize(waterHeightmap, 0);
	ivec2 texelCoords = ivec2(int(round(UV.x*float(size.x-1))), int(round(UV.y*float(size.y-1))));
	float wh = texelFetch(waterHeightmap, texelCoords, 0).r;
	vec4 h = texelFetch(heightmap, texelCoords, 0);
	float cwh = getCombinedHeight(h, wh);
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
	float Rwh = texelFetch(waterHeightmap, Rtc, 0).r;
	float Bwh = texelFetch(waterHeightmap, Btc, 0).r;
	float Lwh = texelFetch(waterHeightmap, Ltc, 0).r;
	float Twh = texelFetch(waterHeightmap, Ttc, 0).r;
	float avgWh = (Rwh+Bwh+Lwh+Twh)/4.0;
	if(wh > avgWh*1.1){
		wh = avgWh*1.1;
	}
	vec4 Rh = texelFetch(heightmap, Rtc, 0);
	vec4 Bh = texelFetch(heightmap, Btc, 0);
	vec4 Lh = texelFetch(heightmap, Ltc, 0);
	vec4 Th = texelFetch(heightmap, Ttc, 0);
	float Rcwh = getCombinedHeight(Rh, Rwh);
	float Bcwh = getCombinedHeight(Bh, Bwh);
	float Lcwh = getCombinedHeight(Lh, Lwh);
	float Tcwh = getCombinedHeight(Th, Twh);
	vec3 R = vec3(detail, Rcwh-cwh, 0.0);
	vec3 B = vec3(0.0, Bcwh-cwh, detail);
	vec3 L = vec3(-detail, Lcwh-cwh, 0.0);
	vec3 T = vec3(0.0, Tcwh-cwh, -detail);
	vec3 RB = cross(B, R);
	vec3 LT = cross(T, L);
	if(texelCoords.x > 0 && texelCoords.y > 0 && texelCoords.x < size.x-1 && texelCoords.y < size.y-1){
		NORMAL = normalize(RB+LT);
	}
	VERTEX.y = cwh;//+foamHeight;
}

vec3 lerp_color(vec3 color1, vec3 color2, float p){
	p = clamp(p, 0.0, 1.0);
    return color1+(color2-color1)*p;
}

void fragment() {
	float h = texture(waterHeightmap, UV).r;
	vec2 xTexel = 1.0 / vec2(textureSize(velXmap, 0));
	vec2 yTexel = 1.0 / vec2(textureSize(velYmap, 0));
	float vX1 = sqrt(pow(texture(velXmap, UV).r, 2.0));
	float vX2 = sqrt(pow(texture(velXmap, vec2(UV.x+xTexel.x, UV.y)).r, 2.0));
	float vY1 = sqrt(pow(texture(velXmap, UV).r, 2.0));
	float vY2 = sqrt(pow(texture(velXmap, vec2(UV.x, UV.y+yTexel.y)).r, 2.0));
	float v = (vX1 + vX2 + vY1 + vY2)/4.0;
	float foamPercent = clamp((v-minFoamSpeed)/(maxFoamSpeed-minFoamSpeed), 0.0, 1.0);
	ALPHA = min(1.0, h/0.05);
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
	//ALBEDO = vec3(1.0);
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