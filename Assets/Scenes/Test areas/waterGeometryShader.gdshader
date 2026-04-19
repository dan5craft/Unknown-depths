shader_type spatial;

uniform sampler2D heightmap;
uniform float detail;
uniform float absorptionCoefficient = 0.2;
uniform vec3 waterColor;
uniform sampler2D depthTexture:hint_depth_texture;
uniform sampler2D screenTexture;

render_mode cull_disabled;
render_mode depth_draw_always;

void vertex() {
	float h = texture(heightmap, UV).r;
	VERTEX.y = h;
	vec2 texel = 1.0 / vec2(textureSize(heightmap, 0));
	vec3 R = vec3(detail, texture(heightmap, clamp(vec2(UV.x+texel.x, UV.y), vec2(0.0), vec2(1.0))).r-h, 0.0);
	vec3 B = vec3(0.0, texture(heightmap, clamp(vec2(UV.x, UV.y+texel.y), vec2(0.0), vec2(1.0))).r-h, detail);
	NORMAL = normalize(cross(B, R));
}

vec3 lerp_color(vec3 color1, vec3 color2, float p){
    return color1+(color2-color1)*p;
}

void fragment() {
	float h = texture(heightmap, UV).r;
	if(h<0.001){
		ALPHA = 0.0;
	}
	ROUGHNESS = 0.1;
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
	ALBEDO = lerp_color(waterColor*screenColor, screenColor, absorption)*absorption;
	//ALBEDO = vec3(angle, 0.0, 0.0);
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