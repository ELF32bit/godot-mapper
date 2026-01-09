shader_type spatial;

uniform sampler2D albedo_texture: hint_default_white;

uniform float wireframe_width_min = 10.0;
uniform float wireframe_width_max = 20.0;

float barycentric_wireframe(vec4 vertex_color, float fragment_distance, float min_width, float max_width) {
	vec3 coordinates = vertex_color.rgb;
	int mode = int((1.0 - vertex_color.a) * 16.0);
	vec3 icoordinates = vec3(1.0) - vertex_color.rgb;
	vec3 scale = fragment_distance / fwidth(coordinates);
	//scale = vec3(1000.0); // for a smoother relative scale

	bool r_flag = bool(mode & 1);
	bool g_flag = bool(mode & 2);
	bool b_flag = bool(mode & 4);
	bool n_flag = bool(mode & 8);

	float mask = max_width;
	if (!r_flag) { mask = min(mask, coordinates.r * scale.r); }
	if (!g_flag) { mask = min(mask, coordinates.g * scale.g); }
	if (!b_flag) { mask = min(mask, coordinates.b * scale.b); }

	float imask = max_width;
	if (!(r_flag && g_flag && b_flag)) {
		if (!n_flag) { imask = min(imask, icoordinates.r * scale.r); }
		imask = min(imask, icoordinates.g * scale.g);
		imask = min(imask, icoordinates.b * scale.b);
	}

	mask = smoothstep(min_width, max_width, mask);
	imask = smoothstep(min_width, max_width, imask);
	return min(mask, imask);
}

varying float fragment_distance;


void vertex() {
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	fragment_distance = distance(CAMERA_POSITION_WORLD, world_position);
}


void fragment() {
	ALBEDO = vec3(barycentric_wireframe(COLOR, fragment_distance, wireframe_width_min, wireframe_width_max));
	ALBEDO *= texture(albedo_texture, UV).rgb;
}
