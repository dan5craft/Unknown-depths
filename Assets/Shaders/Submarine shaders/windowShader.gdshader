shader_type spatial;

uniform sampler2D windowTexture;

render_mode unshaded;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 windowColor = pow(texture(windowTexture, SCREEN_UV).rgb, vec3(2.2));
	ALBEDO = windowColor;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
