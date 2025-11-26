shader_type fog;

uniform vec3 albedo : source_color = vec3(0.18, 0.3, 0.45);

void fog() {
	float dist = 2.0/pow(length(OBJECT_POSITION-WORLD_POSITION), 2.0);
	DENSITY = clamp(dist, 0.0, 1.0);
	ALBEDO = albedo;
}
