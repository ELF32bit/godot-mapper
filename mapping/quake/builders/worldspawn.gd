@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var static_body := MapperUtilities.create_merged_brush_entity(entity, "StaticBody3D")
	if not static_body:
		return null

	var node := Node3D.new()
	node.transform = static_body.transform
	MapperUtilities.add_global_child(static_body, node, map.settings)

	# creating worldspawn navigation region
	var navigation_region := MapperUtilities.create_navigation_region(entity, static_body, true)
	var navigation_group := navigation_region.navigation_mesh.geometry_source_group_name
	MapperUtilities.add_to_navigation_region(static_body, navigation_region)

	# adding map entities to worldspawn navigation region
	for map_entity in map.classnames.get("func_detail", []):
		map_entity.node_groups.append(navigation_group)

	return node


static func post_build_environment(map: MapperMap) -> void:
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	sky.radiance_size = Sky.RADIANCE_SIZE_128

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_color = Environment.AMBIENT_SOURCE_BG
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.sky = sky

	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_light_color = Color(0.518, 0.553, 0.608)
	environment.fog_sky_affect = 0.0
	environment.fog_density = 0.01

	var world_environment := WorldEnvironment.new()
	map.node.add_child(world_environment, map.settings.readable_node_names)
	world_environment.environment = environment

	var directional_light := DirectionalLight3D.new()
	map.node.add_child(directional_light, map.settings.readable_node_names)
	directional_light.rotation = Vector3(deg_to_rad(-45.0), deg_to_rad(60.0), 0.0)
	directional_light.light_bake_mode = Light3D.BAKE_STATIC
	directional_light.shadow_enabled = true
	directional_light.light_energy = 4.0
