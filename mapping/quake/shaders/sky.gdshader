shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled, unshaded;

uniform sampler2D albedo_texture: source_color, filter_nearest;
uniform float emission_energy = 8.0;


void fragment() {
	mat4 camera_matrix = MODEL_MATRIX * INV_VIEW_MATRIX;
	vec3 camera_position = camera_matrix[3].xyz;
	vec3 fragment_position = (camera_matrix * vec4(VERTEX, 1.0)).xyz;
	vec3 direction = fragment_position - camera_position;
	direction.y = direction.y * 3.0; // flatten the sphere

	ivec2 texture_size = textureSize(albedo_texture, 0);
	float unit_scale = 6.0 * 63.0 / float(texture_size.y);

	direction = normalize(direction) * unit_scale;
	vec2 camera_uv = vec2(direction.x, direction.z);

	float front_scroll = TIME * 0.15;
	float back_scroll = front_scroll / 2.0;

	float back_ui = floor(camera_uv.x + back_scroll);
	float back_uf = (camera_uv.x + back_scroll - back_ui) * 0.5;

	float front_ui = floor(camera_uv.x + front_scroll);
	float front_uf = (camera_uv.x + front_scroll - front_ui) * 0.5;

	vec2 back_uv = vec2(0.5 + back_ui + back_uf, camera_uv.y + back_scroll);
	vec2 front_uv = vec2(front_ui + front_uf, camera_uv.y + front_scroll);

	vec3 back_color = texture(albedo_texture, back_uv).xyz;
	vec3 front_color = texture(albedo_texture, front_uv).xyz;
	if (front_color.x + front_color.y + front_color.z < 0.01) {
		front_color = back_color;
	}

	ALBEDO = front_color;
	EMISSION = front_color * emission_energy;
}