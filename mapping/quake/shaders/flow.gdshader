shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform sampler2D albedo_texture: source_color;
uniform float flow_intensity = 0.15;
uniform float flow_speed = 2.0;

uniform bool emission_enabled = false;
uniform float emission_energy_multiplier = 4.0;

uniform bool quake_water = true;


void fragment() {
	vec2 flow_uv;
	flow_uv.x = UV.x + flow_intensity * sin(TIME * flow_speed + UV.y);
	flow_uv.y = UV.y + flow_intensity * sin(TIME * flow_speed + UV.x);

	ALBEDO = texture(albedo_texture, flow_uv).xyz;
	METALLIC = 0.0; SPECULAR = 0.0;
	ROUGHNESS = 1.0;

	if (emission_enabled) {
		EMISSION = ALBEDO * emission_energy_multiplier;
	}

	if (quake_water) {
		//vec3 world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		vec3 world_normal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
		ALPHA = float(abs(dot(world_normal, vec3(0.0, 1.0, 0.0))) > 0.90);
	}
}