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

render_mode unshaded_albedo;

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
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	vec3 screenColor = pow(texture(screenTexture, SCREEN_UV).rgb, vec3(2.2));
	float depth = texture(depthTexture, SCREEN_UV).r;
	depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
	depth += VERTEX.z;
	float absorption = exp(-absorptionCoefficient*depth);
	int blurDetail = 20;
	float angleStep = 2.0*PI/float(blurDetail);
	float blurAmount = 0.004*(1.0-absorption);
	for(int i=0;i<blurDetail;i++){
		screenColor += pow(textureLod(screenTexture, SCREEN_UV+vec2(cos(angleStep*float(i))*blurAmount, sin(angleStep*float(i))*blurAmount), 2.0).xyz, vec3(2.2));
		screenColor += pow(textureLod(screenTexture, SCREEN_UV+vec2(cos(angleStep*float(i)+angleStep*0.5)*blurAmount/2.0, sin(angleStep*float(i))*blurAmount/2.0), 2.0).xyz, vec3(2.2));
	}
	screenColor /= float(blurDetail*2+1);
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
	float mult = (brightness/waterBrightness)*0.4;
	vec3 color = mix(albedo*screenColor, screenColor, absorption);
	ALBEDO = color*absorption;
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
	vec2 pos = VIEW.xy;
	vec2 lightPos = -LIGHT.xy;
	float dist = clamp(1.0-length(lightPos-pos), 0.0, 1.0);
	float angle = clamp(asin(-LIGHT.z)/(2.0*PI), 0.0, 1.0);
	float mult = 0.05;
	SPECULAR_LIGHT += specularBRDF * LIGHT_COLOR * ATTENUATION+ATTENUATION*ALBEDO*LIGHT_COLOR*sqrt(pow(dot(NORMAL, LIGHT), 2))+clamp((albedo*dist*LIGHT_COLOR*angle+albedo*LIGHT_COLOR)*mult*clamp(ATTENUATION, 0.0, 1.0), vec3(0.0), albedo);;
	// Diffuse light (Lambert).
	//DIFFUSE_LIGHT = vec3(1.0);
}