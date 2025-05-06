shader_type spatial;

uniform float wireframe_width_min = 10.0;
uniform float wireframe_width_max = 20.0;

float generate_precise_wireframe(vec4 vertex_color, float fragment_distance, float min_width, float max_width) {
	vec3 wireframe_coordinates = vertex_color.rgb;
	int wireframe_mode = int((1.0 - vertex_color.a) * 8.0);
	vec3 wireframe_scale = fragment_distance / fwidth(wireframe_coordinates);

	float wireframe_mask = max_width;
	if (!bool(1 & wireframe_mode)) {
		wireframe_mask = min(wireframe_mask, wireframe_coordinates.r * wireframe_scale.r);
	}
	if (!bool(2 & wireframe_mode)) {
		wireframe_mask = min(wireframe_mask, wireframe_coordinates.g * wireframe_scale.g);
	}
	if (!bool(4 & wireframe_mode)) {
		wireframe_mask = min(wireframe_mask, wireframe_coordinates.b * wireframe_scale.b);
	}

	wireframe_mask = smoothstep(min_width, max_width, wireframe_mask);
	return wireframe_mask;
}

varying float fragment_distance;


void vertex() {
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	fragment_distance = distance(CAMERA_POSITION_WORLD, world_position);
}


void fragment() {
	ALBEDO = vec3(generate_precise_wireframe(COLOR, fragment_distance, wireframe_width_min, wireframe_width_max));
}
