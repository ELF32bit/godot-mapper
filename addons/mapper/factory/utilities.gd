class_name MapperUtilities


static func get_up_vector(settings: MapperSettings) -> Vector3:
	return (settings.basis * Vector3(0.0, 0.0, 1.0)).normalized()


static func get_up_axis_index(settings: MapperSettings) -> int:
	return get_up_vector(settings).abs().max_axis_index()


static func get_up_axis(settings: MapperSettings) -> Vector3:
	var up_axis := Vector3.ZERO
	var up_vector := get_up_vector(settings)
	var up_axis_index := MapperUtilities.get_up_axis_index(settings)
	up_axis[up_axis_index] = signf(up_vector[up_axis_index])
	return up_axis


static func get_forward_vector(settings: MapperSettings) -> Vector3:
	return (settings.basis * Vector3(1.0, 0.0, 0.0)).normalized()


static func get_forward_axis_index(settings: MapperSettings) -> int:
	return get_forward_vector(settings).abs().max_axis_index()


static func get_forward_axis(settings: MapperSettings) -> Vector3:
	var forward_axis := Vector3.ZERO
	var forward_vector := get_forward_vector(settings)
	var forward_axis_index := MapperUtilities.get_forward_axis_index(settings)
	forward_axis[forward_axis_index] = signf(forward_vector[forward_axis_index])
	return forward_axis


static func get_right_vector(settings: MapperSettings) -> Vector3:
	return (settings.basis * Vector3(0.0, -1.0, 0.0)).normalized()


static func get_right_axis_index(settings: MapperSettings) -> int:
	return get_right_vector(settings).abs().max_axis_index()


static func get_right_axis(settings: MapperSettings) -> Vector3:
	var right_axis := Vector3.ZERO
	var right_vector := get_right_vector(settings)
	var right_axis_index := MapperUtilities.get_right_axis_index(settings)
	right_axis[right_axis_index] = signf(right_vector[right_axis_index])
	return right_axis


static func spread_transform_array(transform_array: PackedVector3Array, spread: float) -> PackedVector3Array:
	if transform_array.size() % 4 != 0 or spread < 0.0:
		return PackedVector3Array()
	elif spread == 0.0:
		return transform_array
	var spread_transform_array := PackedVector3Array()
	var spread_squared := spread * spread
	for index in range(0, transform_array.size(), 4):
		var is_new := true
		for index2 in range(0, spread_transform_array.size(), 4):
			if (transform_array[index + 3] - spread_transform_array[index2 + 3]).length_squared() < spread_squared:
				is_new = false
				break
		if is_new:
			spread_transform_array.append(transform_array[index + 0])
			spread_transform_array.append(transform_array[index + 1])
			spread_transform_array.append(transform_array[index + 2])
			spread_transform_array.append(transform_array[index + 3])
	return spread_transform_array


static func change_node_type(node: Node, classname: StringName) -> Node:
	if not ClassDB.is_parent_class(classname, "Node"):
		return null
	if not ClassDB.can_instantiate(classname):
		return null

	var new_node := ClassDB.instantiate(classname)
	for property in node.get_property_list():
		if property.usage and PROPERTY_USAGE_DEFAULT:
			new_node.set(property.name, node.get(property.name))

	node.replace_by(new_node, true)
	if not node.name.is_empty():
		new_node.name = node.name
	node.free()

	return new_node


static func get_tree_transform(node: Node) -> Transform3D:
	var transform := Transform3D.IDENTITY
	var parent: Node = node

	while parent:
		if parent.is_class("Node3D"):
			transform = parent.transform * transform
		parent = parent.get_parent()

	return transform


static func apply_entity_transform(entity: MapperEntity, node: Node3D, erase: bool = false) -> void:
	node.position = entity.node_properties.get("position", entity.center)
	node.rotation = entity.node_properties.get("rotation", Vector3.ZERO)
	node.scale = entity.node_properties.get("scale", Vector3.ONE)
	if erase:
		entity.node_properties.erase("position")
		entity.node_properties.erase("rotation")
		entity.node_properties.erase("scale")


static func add_global_child(child: Node, parent: Node, settings: MapperSettings) -> void:
	if child is Node3D:
		child.transform = get_tree_transform(parent).affine_inverse() * child.transform
	parent.add_child(child, settings.readable_node_names)


static func create_navigation_region(entity: MapperEntity, parent: Node, automatic: bool = false) -> NavigationRegion3D:
	var navigation_region := NavigationRegion3D.new()
	add_global_child(navigation_region, parent, entity.factory.settings)

	var navigation_mesh := NavigationMesh.new()
	var navigation_group_id := entity.factory.random_number_generator.randi()
	navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_BOTH
	navigation_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_EXPLICIT
	navigation_mesh.geometry_source_group_name = "navigation-%s" % navigation_group_id

	if automatic:
		navigation_region.navmesh = navigation_mesh
		navigation_region.ready.connect(navigation_region.bake_navigation_mesh, CONNECT_PERSIST | CONNECT_DEFERRED)
	else:
		var map_source_file := entity.factory.game_loader.source_file
		var map_data_directory := entity.factory.settings.game_directory.path_join(entity.factory.settings.game_map_data_directory)
		var navigation_mesh_path := map_data_directory.path_join("%s-%s-%s.NavigationMesh.res" % [
			map_source_file.get_file().get_basename(),
			map_source_file.hash(),
			navigation_group_id])
		if ResourceSaver.save(navigation_mesh, navigation_mesh_path) == OK:
			navigation_region.navmesh = ResourceLoader.load(navigation_mesh_path, "NavigationMesh")

	return navigation_region


static func add_to_navigation_region(node: Node, navigation_region: NavigationRegion3D) -> void:
	if navigation_region and navigation_region.navmesh:
		node.add_to_group(navigation_region.navmesh.geometry_source_group_name, true)


static func add_entity_to_navigation_region(entity: MapperEntity, navigation_region: NavigationRegion3D) -> void:
	if navigation_region and navigation_region.navmesh:
		entity.node_groups.append(navigation_region.navmesh.geometry_source_group_name)


static func create_voxel_gi(map: MapperMap, parent: Node, aabb: AABB, scale: float = 1.2, as_first_child: bool = true, automatic: bool = false) -> VoxelGI:
	if not aabb.has_surface():
		return null

	var voxel_gi := VoxelGI.new()
	voxel_gi.position = aabb.get_center()
	add_global_child(voxel_gi, parent, map.settings)
	voxel_gi.transform = voxel_gi.transform.orthonormalized()
	if as_first_child:
		parent.move_child(voxel_gi, 0)

	voxel_gi.extents = clampf(scale, 0.0, INF) * aabb.size / 2.0
	if automatic:
		voxel_gi.ready.connect(voxel_gi.bake, CONNECT_PERSIST)
	else:
		var map_source_file := map.factory.game_loader.source_file
		var map_data_directory := map.settings.game_directory.path_join(map.settings.game_map_data_directory)
		var voxel_gi_data_path := map_data_directory.path_join("%s-%s-%s.VoxelGIData.res" % [
			map_source_file.get_file().get_basename(),
			map_source_file.hash(),
			map.factory.random_number_generator.randi()])
		if ResourceSaver.save(VoxelGIData.new(), voxel_gi_data_path) == OK:
			voxel_gi.data = ResourceLoader.load(voxel_gi_data_path, "VoxelGIData")
	return voxel_gi


static func create_lightmap_gi(map: MapperMap, parent: Node, as_first_child: bool = true) -> LightmapGI:
	var lightmap_gi := LightmapGI.new()
	parent.add_child(lightmap_gi, map.settings.readable_node_names)
	var map_source_file := map.factory.game_loader.source_file
	var map_data_directory := map.settings.game_directory.path_join(map.settings.game_map_data_directory)
	var lightmap_gi_data_path := map_data_directory.path_join("%s-%s-%s.LightmapGIData.lmbake" % [
		map_source_file.get_file().get_basename(),
		map_source_file.hash(),
		map.factory.random_number_generator.randi()])
	if ResourceSaver.save(LightmapGIData.new(), lightmap_gi_data_path) == OK:
		lightmap_gi.light_data = ResourceLoader.load(lightmap_gi_data_path, "LightmapGIData")
	if as_first_child:
		parent.move_child(lightmap_gi, 0)
	return lightmap_gi


static func create_multimesh_instance(entity: MapperEntity, parent: Node, multimesh: MultiMesh, transform_array: PackedVector3Array) -> MultiMeshInstance3D:
	var multimesh_instance := MultiMeshInstance3D.new()
	multimesh_instance.position = entity.center
	add_global_child(multimesh_instance, parent, entity.factory.settings)

	var multimesh_mesh: Mesh = multimesh.mesh
	if entity.factory.settings.lightmap_unwrap:
		if multimesh_mesh and multimesh_mesh is ArrayMesh:
			multimesh_mesh = multimesh_mesh.duplicate()
			var transform := Transform3D.IDENTITY.translated(entity.center)
			multimesh_mesh.lightmap_unwrap(transform, entity.factory.settings.lightmap_texel_size);

	multimesh_instance.multimesh = MultiMesh.new()
	multimesh_instance.multimesh.mesh = multimesh_mesh
	multimesh_instance.multimesh.use_colors = multimesh.use_colors
	multimesh_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh_instance.multimesh.instance_count = transform_array.size() / 4
	multimesh_instance.multimesh.transform_array = transform_array
	multimesh_instance.cast_shadow = int(entity.is_casting_shadow())
	multimesh_instance.gi_mode = MultiMeshInstance3D.GI_MODE_DISABLED

	return multimesh_instance


static func create_multimesh_mesh_instance(entity: MapperEntity, parent: Node, multimesh: MultiMesh, transform_array: PackedVector3Array) -> MeshInstance3D: # TODO: BUG: workaround for baking light on multimeshes
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.position = entity.center
	add_global_child(mesh_instance, parent, entity.factory.settings)

	mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_STATIC

	var multimesh_mesh: Mesh = multimesh.mesh
	if not multimesh_mesh:
		return mesh_instance

	var transforms: Array[Transform3D] = []
	transforms.resize(transform_array.size() / 4)
	for index in range(transform_array.size() / 4):
		var transform := Transform3D.IDENTITY
		transform.basis.x = transform_array[index * 4 + 0]
		transform.basis.y = transform_array[index * 4 + 1]
		transform.basis.z = transform_array[index * 4 + 2]
		var scale := transform.basis.get_scale() # something strange with basis here
		transform.basis = transform.basis.orthonormalized().inverse().scaled(scale)
		transform.origin = transform_array[index * 4 + 3]
		transforms[index] = transform

	var create_array_mesh_from_multimesh := func(multimesh_mesh: Mesh, transforms: Array[Transform3D]) -> ArrayMesh:
		var array_mesh := ArrayMesh.new()
		if transform_array.size() == 0:
			return array_mesh
		elif transform_array.size() % 4 != 0:
			return null

		for surface_index in range(multimesh_mesh.get_surface_count()):
			var array_mesh_arrays := multimesh_mesh.surface_get_arrays(surface_index)
			for array in array_mesh_arrays:
				if array != null:
					array.clear()
			var multimesh_mesh_arrays := multimesh_mesh.surface_get_arrays(surface_index)
			for array_index in range(multimesh_mesh_arrays.size()):
				if multimesh_mesh_arrays[array_index] == null:
					continue
				match array_index:
					ArrayMesh.ARRAY_VERTEX:
						for transform in transforms:
							var array: PackedVector3Array
							array = transform * multimesh_mesh_arrays[array_index]
							array_mesh_arrays[array_index].append_array(array)
					ArrayMesh.ARRAY_NORMAL:
						for transform in transforms:
							var array: PackedVector3Array
							array = multimesh_mesh_arrays[array_index].duplicate()
							for normal_index in range(array.size()):
								array[normal_index] = (transform.basis * array[normal_index]).normalized()
							array_mesh_arrays[array_index].append_array(array)
					ArrayMesh.ARRAY_TANGENT:
						for transform in transforms:
							var array: PackedFloat32Array
							array = multimesh_mesh_arrays[array_index].duplicate()
							for index in range(array.size() / 4):
								var tangent := Vector3.ZERO
								tangent.x = array[index * 4 + 0]
								tangent.y = array[index * 4 + 1]
								tangent.z = array[index * 4 + 2]
								tangent = (transform.basis * tangent).normalized()
								array[index * 4 + 0] = tangent.x
								array[index * 4 + 1] = tangent.y
								array[index * 4 + 2] = tangent.z
								# TODO: array[index * 4 + 3] tangent transform ???
							array_mesh_arrays[array_index].append_array(array)
					ArrayMesh.ARRAY_INDEX:
						var max_index: int = 0
						for index in multimesh_mesh_arrays[array_index]:
							if index > max_index:
								max_index = index
						max_index += 1
						for transform_index in range(transforms.size()):
							var array: PackedInt32Array
							array = multimesh_mesh_arrays[array_index].duplicate()
							for index in range(array.size()):
								array[index] += max_index * transform_index
							array_mesh_arrays[array_index].append_array(array)
					_:
						for transform in transforms:
							var array: Variant = multimesh_mesh_arrays[array_index].duplicate()
							array_mesh_arrays[array_index].append_array(array)
			var blend_shape_arrays := multimesh_mesh.surface_get_blend_shape_arrays(surface_index)
			array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array_mesh_arrays, blend_shape_arrays)
			array_mesh.surface_set_name(surface_index, multimesh_mesh.surface_get_name(surface_index))
			array_mesh.surface_set_material(surface_index, multimesh_mesh.surface_get_material(surface_index))
		return array_mesh

	var array_mesh := create_array_mesh_from_multimesh.call(multimesh_mesh, transforms)
	if multimesh_mesh.shadow_mesh:
		array_mesh.shadow_mesh = create_array_mesh_from_multimesh.call(multimesh_mesh.shadow_mesh, transforms)

	if entity.factory.settings.lightmap_unwrap:
		var transform := Transform3D.IDENTITY.translated(entity.center)
		array_mesh.lightmap_unwrap(transform, entity.factory.settings.lightmap_texel_size);
	mesh_instance.mesh = array_mesh

	return mesh_instance


static func create_brush(entity: MapperEntity, brush: MapperBrush, node_class: StringName = "StaticBody3D", mesh_instance: bool = true, collision_shape: bool = true, occluder_instance: bool = true) -> Node3D:
	if not ClassDB.class_exists(node_class):
		return null
	if not ClassDB.can_instantiate(node_class):
		return null
	if not ClassDB.is_parent_class(node_class, "Node3D"):
		return null

	var node := ClassDB.instantiate(node_class)
	var properties := entity.factory.settings.override_material_metadata_properties
	var has_collision := ClassDB.is_parent_class(node_class, "CollisionObject3D")
	node.position = brush.center
	var has_children := false

	if mesh_instance and brush.mesh:
		var instance := MeshInstance3D.new()
		instance.position = brush.center
		add_global_child(instance, node, entity.factory.settings)
		instance.mesh = brush.mesh
		has_children = true

		if entity.factory.settings.store_base_materials:
			for surface_index in range(brush.mesh.get_surface_count()):
				var surface_name := brush.mesh.surface_get_name(surface_index)
				var material: MapperMaterial = brush.materials.get(surface_name, null)
				if material and material.override:
					instance.set_surface_override_material(surface_index, material.override)

		instance.visible = not brush.get_uniform_property(properties.mesh_disabled, false)
		instance.cast_shadow = int(brush.get_uniform_property(properties.cast_shadow, int(entity.is_casting_shadow())))
		instance.gi_mode = brush.get_uniform_property(properties.gi_mode, MeshInstance3D.GI_MODE_STATIC)
		instance.ignore_occlusion_culling = brush.get_uniform_property(properties.ignore_occlusion, false)

	if collision_shape and has_collision and brush.shape:
		var instance := CollisionShape3D.new()
		instance.position = brush.center
		add_global_child(instance, node, entity.factory.settings)
		instance.shape = brush.shape
		has_children = true

		instance.disabled = brush.get_uniform_property(properties.collision_disabled, false)
		node.collision_layer = brush.get_uniform_property(properties.collision_layer, 1)
		node.collision_mask = brush.get_uniform_property(properties.collision_mask, 1)

	if occluder_instance and brush.occluder:
		var instance := OccluderInstance3D.new()
		instance.position = brush.center
		add_global_child(instance, node, entity.factory.settings)
		instance.occluder = brush.occluder
		has_children = true

		instance.visible = not brush.get_uniform_property(properties.occluder_disabled, false)
		instance.bake_mask = brush.get_uniform_property(properties.occluder_mask, 0xFFFFFFFF)

	if has_children:
		var uniform_material_properties := brush.get_uniform_property_list()
		var reserved_properies := properties.values()
		for uniform_property in uniform_material_properties:
			if not uniform_property in reserved_properies:
				node.set_meta(uniform_property, brush.get_uniform_property(uniform_property))

		if entity.factory.settings.aabb_metadata_property_enabled:
			node.set_meta(entity.factory.settings.aabb_metadata_property, brush.aabb)
		if entity.factory.settings.planes_metadata_property_enabled:
			var planes: Array[Array] = []
			planes.append(brush.get_planes(entity.factory.settings.skip_material_affects_collision))
			node.set_meta(entity.factory.settings.planes_metadata_property, planes)
		return node
	node.free()
	return null


static func create_brush_entity(entity: MapperEntity, node_class: StringName = "Node3D", brush_node_class: StringName = "StaticBody3D", mesh_instance: bool = true, collision_shape: bool = true, occluder_instance: bool = true) -> Node3D:
	if not entity.aabb.has_surface():
		return null
	if not ClassDB.class_exists(node_class):
		return null
	if not ClassDB.can_instantiate(node_class):
		return null
	if not ClassDB.is_parent_class(node_class, "Node3D"):
		return null

	var node: Node3D = ClassDB.instantiate(node_class)
	apply_entity_transform(entity, node)
	var has_children := false

	if not brush_node_class.is_empty():
		for brush in entity.brushes:
			var brush_node := create_brush(entity, brush, brush_node_class, mesh_instance, collision_shape, occluder_instance)
			if brush_node:
				add_global_child(brush_node, node, entity.factory.settings)
				has_children = true
	else:
		for brush in entity.brushes:
			var brush_node := create_brush(entity, brush, node_class, mesh_instance, collision_shape, occluder_instance)
			if brush_node:
				for child in brush_node.get_children():
					brush_node.remove_child(child)
					child.transform = brush_node.transform * child.transform
					add_global_child(child, node, entity.factory.settings)
				brush_node.free()
				has_children = true

	if has_children:
		entity.node_properties.erase("position")
		entity.node_properties.erase("rotation")
		entity.node_properties.erase("scale")

		if entity.factory.settings.aabb_metadata_property_enabled:
			node.set_meta(entity.factory.settings.aabb_metadata_property, entity.aabb)
		if entity.factory.settings.planes_metadata_property_enabled:
			var planes: Array[Array] = []
			for brush in entity.brushes:
				if not brush.is_degenerate:
					planes.append(brush.get_planes(entity.factory.settings.skip_material_affects_collision))
			node.set_meta(entity.factory.settings.planes_metadata_property, planes)
		return node
	node.free()
	return null


static func create_merged_brush_entity(entity: MapperEntity, node_class: StringName, mesh_instance: bool = true, collision_shape: bool = true, occluder_instance: bool = true) -> Node3D:
	if not entity.aabb.has_surface():
		return null
	if not ClassDB.class_exists(node_class):
		return null
	if not ClassDB.can_instantiate(node_class):
		return null
	if not ClassDB.is_parent_class(node_class, "Node3D"):
		return null

	var node: Node3D = ClassDB.instantiate(node_class)
	var has_collision := ClassDB.is_parent_class(node_class, "CollisionObject3D")
	apply_entity_transform(entity, node)
	var has_children := false

	if mesh_instance and entity.mesh:
		var instance := MeshInstance3D.new()
		instance.position = entity.center
		add_global_child(instance, node, entity.factory.settings)
		instance.mesh = entity.mesh
		has_children = true

		if entity.factory.settings.store_base_materials:
			var materials := {}
			for brush in entity.brushes:
				materials.merge(brush.materials, false)
			for surface_index in range(entity.mesh.get_surface_count()):
				var surface_name := entity.mesh.surface_get_name(surface_index)
				var material: MapperMaterial = materials.get(surface_name, null)
				if material and material.override:
					instance.set_surface_override_material(surface_index, material.override)

		instance.cast_shadow = int(entity.is_casting_shadow())

	if collision_shape and has_collision and entity.shape:
		var instance := CollisionShape3D.new()
		instance.position = entity.center
		add_global_child(instance, node, entity.factory.settings)
		instance.shape = entity.shape
		has_children = true

	if occluder_instance and entity.occluder:
		var instance := OccluderInstance3D.new()
		instance.position = entity.center
		add_global_child(instance, node, entity.factory.settings)
		instance.occluder = entity.occluder
		has_children = true

	if has_children:
		entity.node_properties.erase("position")
		entity.node_properties.erase("rotation")
		entity.node_properties.erase("scale")

		if entity.factory.settings.aabb_metadata_property_enabled:
			node.set_meta(entity.factory.settings.aabb_metadata_property, entity.aabb)
		if entity.factory.settings.planes_metadata_property_enabled:
			var planes: Array[Array] = []
			for brush in entity.brushes:
				if not brush.is_degenerate:
					planes.append(brush.get_planes(entity.factory.settings.skip_material_affects_collision))
			node.set_meta(entity.factory.settings.planes_metadata_property, planes)
		return node
	node.free()
	return null


static func create_decal_entity(entity: MapperEntity) -> Decal:
	if not entity.is_decal():
		return null

	var node := Decal.new()
	apply_entity_transform(entity, node, true)
	node.basis = node.basis.orthonormalized()
	node.quaternion = Quaternion(node.basis.y, node.basis.z) * node.quaternion
	node.extents = (node.basis.inverse() * entity.aabb.size).abs() / 2.0

	var material_name := entity.brushes[0].mesh.surface_get_name(0)
	var material: BaseMaterial3D = entity.brushes[0].materials[material_name].base
	node.texture_albedo = material.get_texture(BaseMaterial3D.TEXTURE_ALBEDO)
	node.texture_normal = material.get_texture(BaseMaterial3D.TEXTURE_NORMAL)
	node.texture_orm = material.get_texture(BaseMaterial3D.TEXTURE_ORM)
	node.texture_emission = material.get_texture(BaseMaterial3D.TEXTURE_EMISSION)
	node.emission_energy = material.emission_intensity # BUG: different property names
	node.modulate = material.albedo_color

	return node


static func create_reset_animation(animation_player: AnimationPlayer, animation_library: AnimationLibrary) -> void:
	if animation_library.has_animation("RESET"):
		animation_library.remove_animation("RESET")
	var reset_animation := Animation.new()
	reset_animation.length = 0.0

	for animation_name in animation_library.get_animation_list():
		var animation := animation_library.get_animation(animation_name)
		for track_index in range(animation.get_track_count()):
			var track_path := animation.track_get_path(track_index)
			var track_type := animation.track_get_type(track_index)
			if reset_animation.find_track(track_path, track_type) != -1:
				continue

			var track_path_node := NodePath(track_path.get_concatenated_names())
			var track_path_property := NodePath(track_path.get_concatenated_subnames())
			match track_type:
				Animation.TrackType.TYPE_VALUE:
					pass
				Animation.TrackType.TYPE_POSITION_3D:
					track_path_property = "position"
				Animation.TrackType.TYPE_ROTATION_3D:
					track_path_property = "quaternion"
				Animation.TrackType.TYPE_SCALE_3D:
					track_path_property = "scale"
				_:
					continue

			var animation_player_root := animation_player.get_node_or_null(animation_player.root_node)
			if not animation_player_root:
				continue
			var node := animation_player_root.get_node_or_null(track_path_node)
			if not node:
				continue
			var property_value: Variant = node.get_indexed(track_path_property)
			var reset_track_index := reset_animation.get_track_count()

			reset_animation.add_track(track_type)
			reset_animation.track_set_path(reset_track_index, track_path)
			reset_animation.track_insert_key(reset_track_index, 0.0, property_value)
			reset_animation.track_set_imported(reset_track_index, true)
	animation_library.add_animation("RESET", reset_animation)


static func remove_repeating_animation_keys(animation: Animation) -> void:
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) > Animation.TYPE_VALUE:
			continue

		var duplicate_keys: Array[float] = []
		var track_key_count := animation.track_get_key_count(track_index)
		var current_key_value: Variant = null
		if track_key_count > 0:
			current_key_value = animation.track_get_key_value(track_index, 0)

		for key_index in range(1, track_key_count):
			var key_value: Variant = animation.track_get_key_value(track_index, key_index)
			if is_same(current_key_value, key_value):
				var key_time := animation.track_get_key_time(track_index, key_index)
				duplicate_keys.append(key_time)
			current_key_value = key_value

		if track_key_count > 2 and animation.loop_mode == Animation.LOOP_PINGPONG:
			var ping_pong_duplicate_keys: Array[float] = []
			for key_index in range(track_key_count - 1, -1, -1):
				var key_value: Variant = animation.track_get_key_value(track_index, key_index)
				if is_same(current_key_value, key_value):
					var key_time := animation.track_get_key_time(track_index, key_index)
					var duplicate_index := duplicate_keys.rfind(key_time)
					if duplicate_index != -1:
						for index in range(duplicate_keys.size() - 1, duplicate_index - 1, -1):
							duplicate_keys.remove_at(index)
						ping_pong_duplicate_keys.append(key_time)
				current_key_value = key_value

			for key_time in ping_pong_duplicate_keys:
				animation.track_remove_key_at_time(track_index, key_time)
		else:
			for key_time in duplicate_keys:
				animation.track_remove_key_at_time(track_index, key_time)
