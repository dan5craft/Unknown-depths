shader_type spatial;

uniform sampler2D waterHeightmap;
uniform sampler2D heightmap;
uniform sampler2D velXmap;
uniform sampler2D velYmap;
uniform float detail;
uniform float absorptionCoefficient;
uniform float minFoamSpeed = 0.5;
uniform float maxFoamSpeed = 3.0;
uniform vec3 waterColor;
uniform sampler2D depthTexture:hint_depth_texture;
uniform sampler2D screenTexture;
uniform sampler2D noiseTexture;

render_mode cull_disabled;
render_mode depth_draw_always;

void vertex() {
	ivec2 size = textureSize(waterHeightmap, 0);
	ivec2 texelCoords = ivec2(int(round(UV.x*float(size.x-1))), int(round(UV.y*float(size.y-1))));
	float wh = texelFetch(waterHeightmap, texelCoords, 0).r;
	float h = texelFetch(heightmap, texelCoords, 0).r;
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
	vec2 texel = 1.0 / vec2(textureSize(waterHeightmap, 0));
	float Rwh = texture(waterHeightmap, vec2(clamp(UV.x+texel.x, 0.0, 1.0), UV.y)).r;
	float Bwh = texture(waterHeightmap, vec2(UV.x, clamp(UV.y+texel.y, 0.0, 1.0))).r;
	float Lwh = texture(waterHeightmap, vec2(clamp(UV.x-texel.x, 0.0, 1.0), UV.y)).r;
	float Twh = texture(waterHeightmap, vec2(UV.x, clamp(UV.y-texel.y, 0.0, 1.0))).r;
	float avgWh = (Rwh+Bwh+Lwh+Twh)/4.0;
	if(wh > avgWh*1.25){
		wh = avgWh*1.25;
	}
	float Rh = Rwh + texture(heightmap, vec2(clamp(UV.x+texel.x, 0.0, 1.0), UV.y)).r;
	float Bh = Bwh + texture(heightmap, vec2(UV.x, clamp(UV.y+texel.y, 0.0, 1.0))).r;
	float Lh = Lwh + texture(heightmap, vec2(clamp(UV.x-texel.x, 0.0, 1.0), UV.y)).r;
	float Th = Twh + texture(heightmap, vec2(UV.x, clamp(UV.y-texel.y, 0.0, 1.0))).r;
	vec3 R = vec3(detail, Rh-(h+wh), 0.0);
	vec3 B = vec3(0.0, Bh-(h+wh), detail);
	vec3 L = vec3(-detail, Lh-(h+wh), 0.0);
	vec3 T = vec3(0.0, Th-(h+wh), -detail);
	vec3 RB = cross(B, R);
	vec3 LT = cross(T, L);
	if(texelCoords.x > 1 && texelCoords.y > 1 && texelCoords.x < size.x-2 && texelCoords.y < size.y-2){
		NORMAL = normalize(RB+LT);
	}
	VERTEX.y = h+wh;//+foamHeight;
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
	float foamPercent = 0.0;//clamp((v-minFoamSpeed)/(maxFoamSpeed-minFoamSpeed), 0.0, 1.0);
	if(h<0.0001){
		ALPHA = 0.0;
	}
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
	vec3 color = lerp_color(waterColor*screenColor, screenColor, absorption)*absorption+waterColor*0.1*(1.0-absorption);
	//ALBEDO = lerp_color(waterColor*screenColor, screenColor, absorption)*absorption;
	if(v >= minFoamSpeed){
		ALBEDO = lerp_color(color, vec3(1.0), foamPercent);
		//ALBEDO = color;
	} else{
		ALBEDO = color;
	}
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