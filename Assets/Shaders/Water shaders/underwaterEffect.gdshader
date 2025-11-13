shader_type spatial;

uniform vec3 albedo : source_color = vec3(0.18, 0.3, 0.45);
uniform float absorptionCoefficient = 0.05;

uniform sampler2D depthTexture:hint_depth_texture;
uniform sampler2D screenTexture:filter_linear_mipmap;

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 screenColor = pow(textureLod(screenTexture, SCREEN_UV, 2.0).xyz, vec3(2.2));
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
	float mult = brightness/waterBrightness*0.4;
	vec3 color = mix(albedo*screenColor, screenColor, absorption);
	ALBEDO = color*absorption;
}

void light(){
	vec2 pos = VIEW.xy;
	vec2 lightPos = -LIGHT.xy;
	float dist = clamp(1.0-length(lightPos-pos), 0.0, 1.0)*6.0;
	float angle = clamp(asin(-LIGHT.z)/(2.0*PI), 0.0, 1.0);
	float mult = 0.05;
	SPECULAR_LIGHT += clamp((albedo*dist*LIGHT_COLOR*angle+albedo*LIGHT_COLOR)*mult*clamp(ATTENUATION, 0.0, 1.0), vec3(0.0), albedo);
	DIFFUSE_LIGHT = vec3(1.0);
}