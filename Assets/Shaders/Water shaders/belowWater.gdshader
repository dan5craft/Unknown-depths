shader_type spatial;

uniform vec3 albedo : source_color = vec3(0.18, 0.3, 0.45);
uniform float absorptionCoefficient = 0.05;
uniform float metallic : hint_range(0.0, 1.0, 0.1) = 0;
uniform float roughness : hint_range(0.0, 1.0, 0.1) = 0.1;
uniform float specular : hint_range(0.0, 1.0, 0.1) = 0.3;
uniform vec2 waveDirection = vec2(1.0, 0.0);
uniform vec2 waveDirection2 = vec2(0.0, 1.0);
uniform float time_scale = 0.01;
uniform float waveHeight = 0.5;
uniform float waveNoiseScale = 50;

varying float height;
varying vec3 worldPos;

uniform sampler2D depthTexture:hint_depth_texture;
uniform sampler2D screenTexture;
uniform sampler2D noiseMap;
uniform sampler2D noiseMap2;
uniform sampler2D waveNoiseMap;

render_mode depth_prepass_alpha;

void vertex() {
	// Called for every vertex the material is visible on.
	worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(waveNoiseMap, worldPos.xz / waveNoiseScale + TIME * time_scale*3.0).r;
	VERTEX.y += height*waveHeight-waveHeight/2.0;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 time = TIME * waveDirection*time_scale;
	vec2 time2 = TIME * waveDirection2*time_scale;
	vec3 normal = mix(texture(noiseMap,UV+time).xyz, texture(noiseMap2,UV+time2).xyz, 0.5);
	NORMAL_MAP = normal;
	vec3 screenColor = textureLod(screenTexture, SCREEN_UV, 1).rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	float depth = -VERTEX.z;
	float absorption = exp(-absorptionCoefficient*depth);
	float brightness = 0.0;
	float waterBrightness = 0.0;
	for(int i=0;i<3;i++){
		if(screenColor[i] > brightness){
			brightness = screenColor[i];
		}
		if(albedo[i] > waterBrightness){
			waterBrightness = albedo[i];
		}
	}
	float mult = brightness/waterBrightness*0.4;
	vec3 color = mix(albedo*screenColor, screenColor, absorption);
	ALBEDO = color;
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

vec3 SchlickBaseReflectivity()
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
	
	float NdotL = max(dot(NORMAL, LIGHT), 0.0);
	float NdotV = max(dot(NORMAL, VIEW), 0.0);
	float NdotH = max(dot(NORMAL, half), 0.0);
	float LdotH = max(dot(LIGHT, half), 0.0);
	
	// Specular light (Schlick-GGX).
	float ggxAlpha = ROUGHNESS * ROUGHNESS;
	float D = DistributionGGX(NdotH, ggxAlpha);
	float G = GeometryGGX(NdotL, NdotV, ggxAlpha);
	
	vec3 f0 = SchlickBaseReflectivity();
	float LdotH5 = SchlickFresnel(LdotH);
	float f90 = clamp(50.0 * f0.g, 0.0, 1.0);
	vec3 F = f0 + (f90 - f0) * LdotH5;
	
	vec3 specularBRDF = max(NdotL * D * G * F, 0.0);
	SPECULAR_LIGHT += specularBRDF * LIGHT_COLOR * ATTENUATION+ATTENUATION*ALBEDO*LIGHT_COLOR*sqrt(pow(dot(NORMAL, LIGHT), 2))*0.2;
	// Diffuse light (Lambert).
	//DIFFUSE_LIGHT += vec3(1.0);
}
