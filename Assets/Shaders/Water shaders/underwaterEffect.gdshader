shader_type spatial;

uniform vec3 albedo : source_color = vec3(0.18, 0.3, 0.45);
uniform float absorptionCoefficient = 0.05;

varying float vertex;

uniform sampler2D depthTexture:hint_depth_texture;
uniform sampler2D screenTexture;
uniform sampler2D lightTexture;

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 screenColor = pow(texture(screenTexture, SCREEN_UV).xyz, vec3(2.2));
	float depth = texture(depthTexture, SCREEN_UV).r;
	depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
	vertex = VERTEX.z;
	depth += VERTEX.z;
	float absorption = exp(-absorptionCoefficient*depth);
	int blurDetail = 20;
	float angleStep = 2.0*PI/float(blurDetail);
	float blurAmount = 0.004*(1.0-absorption);
	for(int i=0;i<blurDetail;i++){
		screenColor += pow(texture(screenTexture, SCREEN_UV+vec2(cos(angleStep*float(i))*blurAmount, sin(angleStep*float(i))*blurAmount)).xyz, vec3(2.2));
		screenColor += pow(texture(screenTexture, SCREEN_UV+vec2(cos(angleStep*float(i)+angleStep*0.5)*blurAmount/2.0, sin(angleStep*float(i))*blurAmount/2.0)).xyz, vec3(2.2));
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
	//ALBEDO = color*absorption;
}

void light(){
	vec2 pos = VIEW.xy;
	vec2 lightPos = -LIGHT.xy;
	float dist = clamp(2.0/length(LIGHT_POSITION)-length(lightPos-pos), 0.0, 1.0);
	float angle = clamp(asin(-LIGHT.z)/(2.0*PI), 0.0, 1.0);
	float mult = 0.01;
	float depth = texture(depthTexture, SCREEN_UV).r;
	depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
	depth += vertex;
	vec3 light = LIGHT_COLOR/length(LIGHT_POSITION);
	SPECULAR_LIGHT += (albedo*dist*angle+albedo)*mult*light;//+screenColor*angle*dist*LIGHT_COLOR*mult/depth;
	//SPECULAR_LIGHT += light;
	DIFFUSE_LIGHT = vec3(1.0);
}