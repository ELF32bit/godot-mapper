class_name MapperUtilities


static func lightmap_unwrap(mesh: ArrayMesh, transform: Transform3D, texel_size: float) -> void:
	var surface_names: PackedStringArray = []
	surface_names.resize(mesh.get_surface_count())
	for surface_index in range(mesh.get_surface_count()):
		surface_names[surface_index] = mesh.surface_get_name(surface_index)
	# BUG: lightmap unwrap creates new mesh without surface names
	mesh.lightmap_unwrap(transform, texel_size)
	if surface_names.size() == mesh.get_surface_count():
		for surface_index in range(mesh.get_surface_count()):
			mesh.surface_set_name(surface_index, surface_names[surface_index])


static func is_equal_approximately(a: Vector3, b: Vector3, epsilon: float) -> bool:
	if not absf(a.x - b.x) < epsilon:
		return false
	if not absf(a.y - b.y) < epsilon:
		return false
	if not absf(a.z - b.z) < epsilon:
		return false
	return true


static func spread_transform_array(transform_array: PackedVector3Array, spread: float) -> void:
	if transform_array.size() % 4 != 0 or spread <= 0.0:
		return

	var spread_squared := spread * spread
	var spread_transform_array := PackedVector3Array()
	for index1 in range(0, transform_array.size(), 4):
		var is_new := true
		for index2 in range(0, spread_transform_array.size(), 4):
			if (transform_array[index1 + 3] - spread_transform_array[index2 + 3]).length_squared() < spread_squared:
				is_new = false
				break

		if is_new:
			spread_transform_array.append(transform_array[index1 + 0])
			spread_transform_array.append(transform_array[index1 + 1])
			spread_transform_array.append(transform_array[index1 + 2])
			spread_transform_array.append(transform_array[index1 + 3])
	transform_array.clear()
	transform_array.append_array(spread_transform_array)


static func get_transform_array_positions(transform_array: PackedVector3Array, offset: Vector3 = Vector3.ZERO) -> PackedVector3Array:
	if transform_array.size() % 4 != 0:
		return PackedVector3Array()

	var positions_array := PackedVector3Array()
	positions_array.resize(transform_array.size() / 4)
	for index in range(0, transform_array.size(), 4):
		var x_axis := transform_array[index + 0]
		var y_axis := transform_array[index + 1]
		var z_axis := transform_array[index + 2]
		var basis := Basis(x_axis, y_axis, z_axis)
		var transposed_basis := basis.transposed()

		var offset_direction := Vector3.ZERO
		offset_direction += transposed_basis.x.normalized() * offset.x
		offset_direction += transposed_basis.y.normalized() * offset.y
		offset_direction += transposed_basis.z.normalized() * offset.z

		positions_array[index / 4] = transform_array[index + 3] + offset_direction
	return positions_array


static func scale_transform_array(transform_array: PackedVector3Array, min_scale: Vector3, max_scale: Vector3, offset: Vector3 = Vector3.ZERO, seed: int = 0) -> void:
	if transform_array.size() % 4 != 0:
		return

	var random_number_generator := RandomNumberGenerator.new()
	random_number_generator.seed = seed

	var uniform_xz := false
	if min_scale.x == min_scale.z:
		if max_scale.x == max_scale.z:
			uniform_xz = true
	var scale_range := max_scale - min_scale

	for index in range(0, transform_array.size(), 4):
		var x_axis := transform_array[index + 0]
		var y_axis := transform_array[index + 1]
		var z_axis := transform_array[index + 2]
		var basis := Basis(x_axis, y_axis, z_axis)
		var transposed_basis := basis.transposed()
		var scale := Vector3(min_scale)

		if scale_range.y != 0.0:
			var r1 := random_number_generator.randf()
			scale.y += scale_range.y * r1

		if uniform_xz:
			if scale_range.x != 0.0:
				var r2 := random_number_generator.randf()
				scale.x += scale_range.x * r2
				scale.z += scale_range.z * r2
		else:
			if scale_range.x != 0.0:
				var r2 := random_number_generator.randf()
				scale.x += scale_range.x * r2
			if scale_range.z != 0.0:
				var r3 := random_number_generator.randf()
				scale.z += scale_range.z * r3

		var offset_direction := Vector3.ZERO
		offset_direction += transposed_basis.x.normalized() * offset.x * scale.x
		offset_direction += transposed_basis.y.normalized() * offset.y * scale.y
		offset_direction += transposed_basis.z.normalized() * offset.z * scale.z

		basis = basis.scaled(scale)
		transform_array[index + 0] = basis.x
		transform_array[index + 1] = basis.y
		transform_array[index + 2] = basis.z
		transform_array[index + 3] += offset_direction


static func rotate_transform_array(transform_array: PackedVector3Array, snap_angles: Vector3 = Vector3(-1.0, 0.0, -1.0), offset: Vector3 = Vector3.ZERO, seed: int = 0) -> void:
	if transform_array.size() % 4 != 0:
		return

	var random_number_generator := RandomNumberGenerator.new()
	random_number_generator.seed = seed

	var snap_angles_radians := Vector3.ZERO
	snap_angles_radians.x = deg_to_rad(clampf(snap_angles.x, -1.0, 180.0))
	snap_angles_radians.y = deg_to_rad(clampf(snap_angles.y, -1.0, 180.0))
	snap_angles_radians.z = deg_to_rad(clampf(snap_angles.z, -1.0, 180.0))

	for index in range(0, transform_array.size(), 4):
		var x_axis := transform_array[index + 0]
		var y_axis := transform_array[index + 1]
		var z_axis := transform_array[index + 2]
		var basis := Basis(x_axis, y_axis, z_axis)
		var transposed_basis := basis.transposed()

		var offset_direction := Vector3.ZERO
		offset_direction += transposed_basis.x.normalized() * offset.x
		offset_direction += transposed_basis.y.normalized() * offset.y
		offset_direction += transposed_basis.z.normalized() * offset.z

		if not snap_angles.y < 0.0 and not transposed_basis.y.is_zero_approx():
			var r1 := random_number_generator.randf() * 2.0 * PI
			if snap_angles.y > 0.0:
				r1 = snappedf(r1, snap_angles_radians.y)
			basis *= Basis(transposed_basis.y.normalized(), r1)
			transposed_basis = basis.transposed()

		if not snap_angles.x < 0.0 and not transposed_basis.x.is_zero_approx():
			var r2 := random_number_generator.randf() * 2.0 * PI
			if snap_angles.x > 0.0:
				r2 = snappedf(r2, snap_angles_radians.x)
			basis *= Basis(transposed_basis.x.normalized(), r2)
			transposed_basis = basis.transposed()

		if not snap_angles.z < 0.0 and not transposed_basis.z.is_zero_approx():
			var r3 := random_number_generator.randf() * 2.0 * PI
			if snap_angles.z > 0.0:
				r3 = snappedf(r3, snap_angles_radians.z)
			basis *= Basis(transposed_basis.z.normalized(), r3)
			transposed_basis = basis.transposed()

		transform_array[index + 0] = basis.x
		transform_array[index + 1] = basis.y
		transform_array[index + 2] = basis.z
		transform_array[index + 3] += offset_direction


static func erase_transform_array(transform_array: PackedVector3Array, position: Vector3, radius: float, hardness: float = 1.0, seed: int = 0) -> PackedVector3Array:
	if transform_array.size() % 4 != 0:
		return PackedVector3Array()

	radius = clampf(radius, 0.0, INF)
	hardness = clampf(hardness, 0.0, 1.0)
	if is_zero_approx(radius) or is_zero_approx(hardness):
		return PackedVector3Array()
	var hardness_remap := (hardness - 0.5) * 2.0
	var hardness_factor := 1.0 + minf(hardness_remap, 0.0)

	var random_number_generator := RandomNumberGenerator.new()
	random_number_generator.seed = seed

	var erased_transform_array := PackedVector3Array()
	var painted_transform_array := PackedVector3Array()
	for index in range(0, transform_array.size(), 4):
		var distance := (transform_array[index + 3] - position).length()
		if distance <= radius:
			var probability := 1.0 - clampf(distance / radius, 0.0, 1.0)
			var gradient := pow(probability, 1.0 - hardness_remap)
			probability = lerpf(0.0, gradient, hardness_factor)

			var is_painted := false
			if is_equal_approx(probability, 1.0):
				is_painted = true
			if not is_painted:
				if not is_zero_approx(probability):
					if random_number_generator.randf() <= probability:
						is_painted = true
			if is_painted:
				painted_transform_array.append(transform_array[index + 0])
				painted_transform_array.append(transform_array[index + 1])
				painted_transform_array.append(transform_array[index + 2])
				painted_transform_array.append(transform_array[index + 3])
				continue

		erased_transform_array.append(transform_array[index + 0])
		erased_transform_array.append(transform_array[index + 1])
		erased_transform_array.append(transform_array[index + 2])
		erased_transform_array.append(transform_array[index + 3])
	transform_array.clear()
	transform_array.append_array(erased_transform_array)

	return painted_transform_array


static func change_node_type(node: Node, classname: StringName) -> Node:
	if not ClassDB.is_parent_class(classname, "Node"):
		return null
	if not ClassDB.can_instantiate(classname):
		return null

	var new_node := ClassDB.instantiate(classname)
	for property in node.get_property_list():
		if property.usage & PROPERTY_USAGE_DEFAULT != 0:
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


static func create_navigation_region(map: MapperMap, parent: Node, automatic: bool = false) -> NavigationRegion3D:
	var navigation_region := NavigationRegion3D.new()
	parent.add_child(navigation_region, map.settings.readable_node_names)

	var navigation_mesh := NavigationMesh.new()
	navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_BOTH
	navigation_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_EXPLICIT
	var navigation_group_id := hash("%s+%s" % [map.source_file.hash(), map.factory.random_number_generator.randi()])
	navigation_mesh.geometry_source_group_name = "navigation-%s" % [navigation_group_id]

	if automatic:
		navigation_region.navmesh = navigation_mesh
		navigation_region.ready.connect(navigation_region.bake_navigation_mesh, CONNECT_PERSIST | CONNECT_DEFERRED)
	else:
		var map_data_directory := map.settings.game_directory.path_join(map.settings.game_map_data_directory)
		var navigation_mesh_path := map_data_directory.path_join("%s-%s.NavigationMesh.res" % [
			map.source_file.get_file().get_basename(), navigation_group_id])
		if map.settings.options.get("__navmesh_external", false):
			navigation_region.navmesh = ResourceLoader.load(navigation_mesh_path, "NavigationMesh")
		elif ResourceSaver.save(navigation_mesh, navigation_mesh_path) == OK:
			navigation_region.navmesh = ResourceLoader.load(navigation_mesh_path, "NavigationMesh")

	return navigation_region


static func add_to_navigation_region(node: Node, navigation_region: NavigationRegion3D) -> void:
	if navigation_region and navigation_region.navmesh:
		node.add_to_group(navigation_region.navmesh.geometry_source_group_name, true)


static func add_entity_to_navigation_region(entity: MapperEntity, navigation_region: NavigationRegion3D) -> void:
	if navigation_region and navigation_region.navmesh:
		entity.node_groups.append(navigation_region.navmesh.geometry_source_group_name)


static func create_voxel_gi(map: MapperMap, parent: Node, aabb: AABB, scale: float = 1.25, as_first_child: bool = true, automatic: bool = false) -> VoxelGI:
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
		var map_data_directory := map.settings.game_directory.path_join(map.settings.game_map_data_directory)
		var voxel_gi_id := hash("%s+%s" % [map.source_file.hash(), map.factory.random_number_generator.randi()])
		var voxel_gi_data_path := map_data_directory.path_join("%s-%s.VoxelGIData.res" % [
			map.source_file.get_file().get_basename(), voxel_gi_id])
		if map.settings.options.get("__voxel_data_external", false):
			voxel_gi.data = ResourceLoader.load(voxel_gi_data_path, "VoxelGIData")
		elif ResourceSaver.save(VoxelGIData.new(), voxel_gi_data_path) == OK:
			voxel_gi.data = ResourceLoader.load(voxel_gi_data_path, "VoxelGIData")
	return voxel_gi


static func create_lightmap_gi(map: MapperMap, parent: Node, as_first_child: bool = true) -> LightmapGI:
	var lightmap_gi := LightmapGI.new()
	parent.add_child(lightmap_gi, map.settings.readable_node_names)
	var map_data_directory := map.settings.game_directory.path_join(map.settings.game_map_data_directory)
	var lightmap_gi_id := hash("%s+%s" % [map.source_file.hash(), map.factory.random_number_generator.randi()])
	var lightmap_gi_data_path := map_data_directory.path_join("%s-%s.LightmapGIData.lmbake" % [
		map.source_file.get_file().get_basename(), lightmap_gi_id])
	if map.settings.options.get("__lightmap_external", false):
		lightmap_gi.light_data = ResourceLoader.load(lightmap_gi_data_path, "LightmapGIData")
	elif ResourceSaver.save(LightmapGIData.new(), lightmap_gi_data_path) == OK:
		lightmap_gi.light_data = ResourceLoader.load(lightmap_gi_data_path, "LightmapGIData")
	if as_first_child:
		parent.move_child(lightmap_gi, 0)
	return lightmap_gi


static func create_multimesh_instance(entity: MapperEntity, parent: Node, multimesh: MultiMesh, transform_array: PackedVector3Array) -> MultiMeshInstance3D:
	if transform_array.size() % 4 != 0:
		return null

	var multimesh_instance := MultiMeshInstance3D.new()
	multimesh_instance.position = entity.center
	add_global_child(multimesh_instance, parent, entity.factory.settings)

	var multimesh_mesh: Mesh = multimesh.mesh
	if multimesh_mesh and multimesh_mesh is ArrayMesh:
		if entity.factory.settings.lightmap_unwrap and multimesh_mesh.get_blend_shape_count() == 0:
			multimesh_mesh = multimesh_mesh.duplicate()
			var transform := Transform3D.IDENTITY.translated(entity.center)
			var lightmap_scale: float = entity.get_lightmap_scale_property(1.0)
			var texel_size := entity.factory.settings.lightmap_texel_size / lightmap_scale
			lightmap_unwrap(multimesh_mesh, transform, texel_size)

	multimesh_instance.multimesh = MultiMesh.new()
	multimesh_instance.multimesh.mesh = multimesh_mesh
	multimesh_instance.multimesh.use_colors = multimesh.use_colors
	multimesh_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh_instance.multimesh.instance_count = transform_array.size() / 4
	multimesh_instance.multimesh.transform_array = transform_array
	multimesh_instance.cast_shadow = int(entity.is_casting_shadow())
	multimesh_instance.gi_mode = MultiMeshInstance3D.GI_MODE_DISABLED

	return multimesh_instance


static func create_multimesh_mesh_instance(entity: MapperEntity, parent: Node, multimesh: MultiMesh, transform_array: PackedVector3Array, store_instance_id: bool = true, seed: int = 0) -> MeshInstance3D:
	if transform_array.size() % 4 != 0:
		return null

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.position = entity.center
	add_global_child(mesh_instance, parent, entity.factory.settings)

	mesh_instance.cast_shadow = int(entity.is_casting_shadow())
	mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED

	var untyped_multimesh_mesh: Mesh = multimesh.mesh
	if not untyped_multimesh_mesh:
		return mesh_instance
	if not untyped_multimesh_mesh is ArrayMesh:
		push_warning("Multimesh mesh instance requires ArrayMesh.")
		return mesh_instance

	var multimesh_mesh: ArrayMesh = untyped_multimesh_mesh
	var random_number_generator := RandomNumberGenerator.new()

	var transforms: Array[Transform3D] = []
	transforms.resize(transform_array.size() / 4)
	for index in range(transform_array.size() / 4):
		var transform := Transform3D.IDENTITY
		transform.basis.x = transform_array[index * 4 + 0]
		transform.basis.y = transform_array[index * 4 + 1]
		transform.basis.z = transform_array[index * 4 + 2]
		transform.origin = transform_array[index * 4 + 3]
		transform.basis = transform.basis.transposed()
		transforms[index] = transform

	var transform_array_mesh_arrays := func(destination_arrays: Array, source_arrays: Array, is_blend_shape: bool = false) -> void:
		destination_arrays.resize(ArrayMesh.ARRAY_MAX)
		for array_index in range(source_arrays.size()):
			if source_arrays[array_index] != null:
				destination_arrays[array_index] = source_arrays[array_index].duplicate()
				destination_arrays[array_index].clear()
			else:
				destination_arrays[array_index] = null
		if not is_blend_shape and store_instance_id:
			if source_arrays[ArrayMesh.ARRAY_COLOR] == null:
				destination_arrays[ArrayMesh.ARRAY_COLOR] = PackedColorArray([])

		var has_colors := false
		if source_arrays[ArrayMesh.ARRAY_COLOR] != null:
			if source_arrays[ArrayMesh.ARRAY_COLOR].size() > 0:
				has_colors = true

		var colors_size: int = 0
		if source_arrays[ArrayMesh.ARRAY_COLOR] != null:
			colors_size = source_arrays[ArrayMesh.ARRAY_COLOR].size()
		if source_arrays[ArrayMesh.ARRAY_VERTEX] != null:
			colors_size = source_arrays[ArrayMesh.ARRAY_VERTEX].size()

		for array_index in range(source_arrays.size()):
			if source_arrays[array_index] == null:
				if array_index != ArrayMesh.ARRAY_COLOR:
					continue
				elif is_blend_shape or not store_instance_id:
					continue

			match array_index:
				ArrayMesh.ARRAY_VERTEX:
					for transform in transforms:
						var array := PackedVector3Array()
						array = transform * source_arrays[array_index]
						destination_arrays[array_index].append_array(array)
				ArrayMesh.ARRAY_NORMAL:
					for transform in transforms:
						var array := PackedVector3Array()
						array = source_arrays[array_index].duplicate()
						for index in range(source_arrays[array_index].size()):
							array[index] = (transform.basis * array[index]).normalized()
						destination_arrays[array_index].append_array(array)
				ArrayMesh.ARRAY_TANGENT:
					for transform in transforms:
						var array := PackedFloat32Array()
						array = source_arrays[array_index].duplicate()
						for index in range(array.size() / 4):
							var tangent := Vector3.ZERO
							tangent.x = array[index * 4 + 0]
							tangent.y = array[index * 4 + 1]
							tangent.z = array[index * 4 + 2]
							tangent = (transform.basis * tangent).normalized()
							array[index * 4 + 0] = tangent.x
							array[index * 4 + 1] = tangent.y
							array[index * 4 + 2] = tangent.z
						destination_arrays[array_index].append_array(array)
				ArrayMesh.ARRAY_COLOR:
					if store_instance_id:
						random_number_generator.seed = seed
						for id in range(transforms.size()):
							var array := PackedColorArray()
							if has_colors:
								array = source_arrays[array_index].duplicate()
							if not array.size() > 0:
								array.resize(colors_size)
								array.fill(Color.WHITE)
							var id_remap := random_number_generator.randf()
							for index in range(array.size()):
								array[index].a = clampf(id_remap, 0.0, 1.0)
							destination_arrays[array_index].append_array(array)
					else:
						for transform in transforms:
							destination_arrays[array_index].append_array(source_arrays[array_index])
				ArrayMesh.ARRAY_INDEX:
					var max_index: int = 0
					for index in source_arrays[array_index]:
						if index > max_index:
							max_index = index
					max_index += 1
					for transform_index in range(transforms.size()):
						var array := PackedInt32Array()
						array = source_arrays[array_index].duplicate()
						for index in range(array.size()):
							array[index] += max_index * transform_index
						destination_arrays[array_index].append_array(array)
				_:
					for transform in transforms:
						destination_arrays[array_index].append_array(source_arrays[array_index])

	var create_array_mesh_from_multimesh := func(mesh: ArrayMesh, transforms: Array[Transform3D]) -> ArrayMesh:
		var array_mesh := ArrayMesh.new()
		if transform_array.size() == 0:
			return array_mesh

		array_mesh.blend_shape_mode = mesh.blend_shape_mode
		for blend_shape_index in range(mesh.get_blend_shape_count()):
			array_mesh.add_blend_shape(mesh.get_blend_shape_name(blend_shape_index))

		for surface_index in range(mesh.get_surface_count()):
			var array_mesh_arrays: Array = []
			var multimesh_mesh_arrays := mesh.surface_get_arrays(surface_index)
			transform_array_mesh_arrays.call(array_mesh_arrays, multimesh_mesh_arrays, false)

			var array_mesh_blendshape_arrays: Array = []
			var multimesh_mesh_blendshape_arrays := mesh.surface_get_blend_shape_arrays(surface_index)
			for multimesh_mesh_blendshape_array in multimesh_mesh_blendshape_arrays:
				var array_mesh_blendshape_array: Array = []
				transform_array_mesh_arrays.call(array_mesh_blendshape_array, multimesh_mesh_blendshape_array, true)
				array_mesh_blendshape_arrays.append(array_mesh_blendshape_array)

			var flags: int = 0
			if array_mesh_arrays[ArrayMesh.ARRAY_VERTEX] == null:
				flags = ArrayMesh.ARRAY_FLAG_USES_EMPTY_VERTEX_ARRAY
			array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array_mesh_arrays, array_mesh_blendshape_arrays, {}, flags)
			array_mesh.surface_set_name(surface_index, mesh.surface_get_name(surface_index))
			array_mesh.surface_set_material(surface_index, mesh.surface_get_material(surface_index))

		return array_mesh

	var array_mesh := create_array_mesh_from_multimesh.call(multimesh_mesh, transforms)
	if multimesh_mesh.shadow_mesh and entity.factory.settings.shadow_meshes:
		array_mesh.shadow_mesh = create_array_mesh_from_multimesh.call(multimesh_mesh.shadow_mesh, transforms)

	if entity.factory.settings.lightmap_unwrap and array_mesh.get_blend_shape_count() == 0:
		var transform := Transform3D.IDENTITY.translated(entity.center)
		var lightmap_scale: float = entity.get_lightmap_scale_property(1.0)
		var texel_size := entity.factory.settings.lightmap_texel_size / lightmap_scale
		lightmap_unwrap(array_mesh, transform, texel_size)

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
	var has_collision := ClassDB.is_parent_class(node_class, "CollisionObject3D")
	var is_lightmap_scene := bool(entity.factory.settings.options.get("__lightmap_scene", false))
	var use_approximate_mass := bool(entity.factory.settings.options.get("__mass_approximate", true))
	var properties := entity.factory.settings.override_material_metadata_properties
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

	if collision_shape and has_collision and brush.shape and not is_lightmap_scene:
		var instance := CollisionShape3D.new()
		instance.position = brush.center
		add_global_child(instance, node, entity.factory.settings)
		instance.shape = brush.shape
		has_children = true

		instance.disabled = brush.get_uniform_property(properties.collision_disabled, false)
		node.collision_layer = brush.get_uniform_property(properties.collision_layer, 1)
		node.collision_mask = brush.get_uniform_property(properties.collision_mask, 1)

	if occluder_instance and brush.occluder and not is_lightmap_scene:
		var instance := OccluderInstance3D.new()
		instance.position = brush.center
		add_global_child(instance, node, entity.factory.settings)
		instance.occluder = brush.occluder
		has_children = true

		instance.visible = not brush.get_uniform_property(properties.occluder_disabled, false)
		instance.bake_mask = brush.get_uniform_property(properties.occluder_mask, 0xFFFFFFFF)

	if has_children:
		if ClassDB.is_parent_class(node_class, "RigidBody3D"):
			var mass := brush.get_mass(use_approximate_mass)
			if mass > 0.0: node.set("mass", mass)
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
	var use_approximate_mass := bool(entity.factory.settings.options.get("__mass_approximate", true))
	apply_entity_transform(entity, node)
	var has_children := false
	var children_are_siblings := false

	if not brush_node_class.is_empty():
		for brush in entity.brushes:
			var brush_node := create_brush(entity, brush, brush_node_class, mesh_instance, collision_shape, occluder_instance)
			if brush_node:
				add_global_child(brush_node, node, entity.factory.settings)
				has_children = true
	else: # creating brush nodes siblings under the entity node
		for brush in entity.brushes:
			var brush_node := create_brush(entity, brush, node_class, mesh_instance, collision_shape, occluder_instance)
			if brush_node:
				for child in brush_node.get_children():
					brush_node.remove_child(child)
					child.transform = brush_node.transform * child.transform
					add_global_child(child, node, entity.factory.settings)
				brush_node.free()
				has_children = true
				children_are_siblings = true

	if has_children:
		if children_are_siblings and ClassDB.is_parent_class(node_class, "RigidBody3D"):
			var mass := entity.get_mass(use_approximate_mass)
			if mass > 0.0: node.set("mass", mass)
		entity.node_properties.erase("position")
		entity.node_properties.erase("rotation")
		entity.node_properties.erase("scale")
		return node

	node.free()
	return null


static func create_merged_brush_entity(entity: MapperEntity, node_class: StringName = "StaticBody3D", mesh_instance: bool = true, collision_shape: bool = true, occluder_instance: bool = true) -> Node3D:
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
	var is_lightmap_scene := bool(entity.factory.settings.options.get("__lightmap_scene", false))
	var use_approximate_mass := bool(entity.factory.settings.options.get("__mass_approximate", true))
	apply_entity_transform(entity, node)
	var has_children := false

	if mesh_instance and entity.mesh:
		var instance := MeshInstance3D.new()
		instance.position = entity.center
		add_global_child(instance, node, entity.factory.settings)
		instance.mesh = entity.mesh
		has_children = true

		if entity.factory.settings.store_base_materials:
			var materials: Dictionary = {}
			for brush in entity.brushes:
				materials.merge(brush.materials, false)
			for surface_index in range(entity.mesh.get_surface_count()):
				var surface_name := entity.mesh.surface_get_name(surface_index)
				var material: MapperMaterial = materials.get(surface_name, null)
				if material and material.override:
					instance.set_surface_override_material(surface_index, material.override)

		instance.cast_shadow = int(entity.is_casting_shadow())

	if collision_shape and has_collision and entity.shape and not is_lightmap_scene:
		var instance := CollisionShape3D.new()
		instance.position = entity.center
		add_global_child(instance, node, entity.factory.settings)
		instance.shape = entity.shape
		has_children = true

	if occluder_instance and entity.occluder and not is_lightmap_scene:
		var instance := OccluderInstance3D.new()
		instance.position = entity.center
		add_global_child(instance, node, entity.factory.settings)
		instance.occluder = entity.occluder
		has_children = true

	if has_children:
		if ClassDB.is_parent_class(node_class, "RigidBody3D"):
			var mass := entity.get_mass(use_approximate_mass)
			if mass > 0.0: node.set("mass", mass)
		entity.node_properties.erase("position")
		entity.node_properties.erase("rotation")
		entity.node_properties.erase("scale")
		return node

	node.free()
	return null


static func create_csg_merged_brush_entity(entity: MapperEntity, brushes: Array[MapperBrush], node_class: StringName = "StaticBody3D", mesh_instance: bool = true, collision_shape: bool = true, occluder_instance: bool = true) -> Node3D:
	if not brushes.size():
		return null
	if not ClassDB.class_exists(node_class):
		return null
	if not ClassDB.can_instantiate(node_class):
		return null
	if not ClassDB.is_parent_class(node_class, "Node3D"):
		return null

	for brush in brushes:
		for face in brush.faces:
			if face.skip:
				push_warning("CSG merged brush entity does not support skip material.")
				return null

	var node: Node3D = ClassDB.instantiate(node_class)
	var has_collision := ClassDB.is_parent_class(node_class, "CollisionObject3D")
	var is_lightmap_scene := bool(entity.factory.settings.options.get("__lightmap_scene", false))
	var use_approximate_mass := bool(entity.factory.settings.options.get("__mass_approximate", true))
	var properties := entity.factory.settings.override_material_metadata_properties
	apply_entity_transform(entity, node)
	var has_children := false

	var csg_mesh: ArrayMesh = null
	if mesh_instance:
		var csg_mesh_combiner := CSGCombiner3D.new()
		csg_mesh_combiner.position = entity.center
		for brush in brushes:
			if brush.is_degenerate:
				continue
			if brush.get_uniform_property(properties.mesh_disabled, false, true):
				continue
			var csg := CSGMesh3D.new()
			csg.mesh = brush.mesh
			csg.position = brush.center
			add_global_child(csg, csg_mesh_combiner, entity.factory.settings)
		if csg_mesh_combiner.get_child_count() > 0:
			if csg_mesh_combiner.has_method("bake_static_mesh"):
				csg_mesh = csg_mesh_combiner.call("bake_static_mesh")
		csg_mesh_combiner.free()

	var has_shadow_mesh := false
	var csg_shadow_mesh: ArrayMesh = null
	if mesh_instance and entity.factory.settings.shadow_meshes:
		var csg_shadow_mesh_combiner := CSGCombiner3D.new()
		csg_shadow_mesh_combiner.position = entity.center
		for brush in brushes:
			if brush.is_degenerate:
				continue
			if brush.get_uniform_property(properties.mesh_disabled, false, true):
				continue
			if not brush.get_uniform_property(properties.cast_shadow, true, true):
				has_shadow_mesh = true
				continue
			var csg := CSGMesh3D.new()
			csg.mesh = brush.mesh
			csg.position = brush.center
			add_global_child(csg, csg_shadow_mesh_combiner, entity.factory.settings)
		if csg_shadow_mesh_combiner.get_child_count() > 0:
			if csg_shadow_mesh_combiner.has_method("bake_static_mesh"):
				csg_shadow_mesh = csg_shadow_mesh_combiner.call("bake_static_mesh")
		csg_shadow_mesh_combiner.free()

	var csg_shape: ConcavePolygonShape3D = null
	if collision_shape and has_collision and not is_lightmap_scene:
		var csg_shape_combiner := CSGCombiner3D.new()
		csg_shape_combiner.position = entity.center
		for brush in brushes:
			if brush.is_degenerate:
				continue
			if brush.get_uniform_property(properties.collision_disabled, false, true):
				continue
			var csg := CSGMesh3D.new()
			csg.mesh = brush.mesh
			csg.position = brush.center
			add_global_child(csg, csg_shape_combiner, entity.factory.settings)
		if csg_shape_combiner.get_child_count() > 0:
			if csg_shape_combiner.has_method("bake_collision_shape"):
				csg_shape = csg_shape_combiner.call("bake_collision_shape")
		csg_shape_combiner.free()

	var csg_occluder_mesh: ArrayMesh = null
	var csg_occluder: ArrayOccluder3D = null
	if occluder_instance and entity.factory.settings.occlusion_culling and not is_lightmap_scene:
		var csg_occluder_combiner := CSGCombiner3D.new()
		csg_occluder_combiner.position = entity.center
		for brush in brushes:
			if brush.is_degenerate:
				continue
			if brush.get_uniform_property(properties.occluder_disabled, false, true):
				continue
			var csg := CSGMesh3D.new()
			csg.mesh = brush.mesh
			csg.position = brush.center
			add_global_child(csg, csg_occluder_combiner, entity.factory.settings)
		if csg_occluder_combiner.get_child_count() > 0:
			if csg_occluder_combiner.has_method("bake_static_mesh"):
				csg_occluder_mesh = csg_occluder_combiner.call("bake_static_mesh")
		csg_occluder_combiner.free()

	if csg_mesh and entity.factory.settings.lightmap_unwrap:
		var transform := Transform3D.IDENTITY.translated(entity.center)
		var lightmap_scale: float = entity.get_lightmap_scale_property(1.0)
		var texel_size := entity.factory.settings.lightmap_texel_size / lightmap_scale
		lightmap_unwrap(csg_mesh, transform, texel_size)

	if csg_mesh:
		var surfaces: Dictionary = {}
		for brush in brushes:
			for material_name in brush.materials:
				surfaces[brush.materials[material_name].base] = material_name
				surfaces[brush.materials[material_name].override] = material_name
		for surface_index in range(csg_mesh.get_surface_count()):
			var surface_material := csg_mesh.surface_get_material(surface_index)
			var surface_name: String = surfaces.get(surface_material, "")
			csg_mesh.surface_set_name(surface_index, surface_name)
		if has_shadow_mesh:
			var surface_tools: Array[SurfaceTool] = []
			surface_tools.resize(csg_mesh.get_surface_count())
			surface_tools.fill(null)

			for surface_index in range(csg_mesh.get_surface_count()):
				var surface_name := csg_mesh.surface_get_name(surface_index)
				for shadow_surface_index in range(csg_shadow_mesh.get_surface_count() if csg_shadow_mesh else 0):
					var shadow_surface_material := csg_shadow_mesh.surface_get_material(shadow_surface_index)
					var shadow_surface_name: String = surfaces.get(shadow_surface_material, "")
					if surface_name == shadow_surface_name and not surface_name.is_empty():
						surface_tools[surface_index] = SurfaceTool.new()
						surface_tools[surface_index].append_from(csg_shadow_mesh, shadow_surface_index, Transform3D.IDENTITY)
						break
				if surface_tools[surface_index] == null:
					surface_tools[surface_index] = SurfaceTool.new()
					surface_tools[surface_index].begin(Mesh.PRIMITIVE_TRIANGLES)
					var triangle := PackedVector3Array()
					triangle.resize(3) # hacking shadow mesh by inserting empty triangle
					triangle.fill(Vector3.ZERO)
					surface_tools[surface_index].add_triangle_fan(triangle)
			for surface_tool in surface_tools:
				surface_tool.index()

			if not csg_mesh.shadow_mesh:
				csg_mesh.shadow_mesh = ArrayMesh.new()
			var flags := Mesh.ARRAY_FORMAT_VERTEX | Mesh.ARRAY_FORMAT_INDEX
			for surface_index in range(csg_mesh.get_surface_count()):
				var surface_name := csg_mesh.surface_get_name(surface_index)
				csg_mesh.shadow_mesh = surface_tools[surface_index].commit(csg_mesh.shadow_mesh, flags)
				var new_surface_index := csg_mesh.shadow_mesh.get_surface_count() - 1
				csg_mesh.shadow_mesh.surface_set_name(new_surface_index, surface_name)

	if csg_occluder_mesh:
		var surface_tool := SurfaceTool.new()
		for surface_index in range(csg_occluder_mesh.get_surface_count()):
			surface_tool.append_from(csg_occluder_mesh, surface_index, Transform3D.IDENTITY)
		surface_tool.index()
		var arrays := surface_tool.commit_to_arrays()
		if arrays[Mesh.ARRAY_VERTEX] and arrays[Mesh.ARRAY_INDEX]:
			var occluder := ArrayOccluder3D.new()
			occluder.set_arrays(arrays[Mesh.ARRAY_VERTEX], arrays[Mesh.ARRAY_INDEX])
			csg_occluder = occluder

	if csg_mesh:
		var instance := MeshInstance3D.new()
		instance.position = entity.center
		add_global_child(instance, node, entity.factory.settings)
		instance.mesh = csg_mesh
		has_children = true

		if entity.factory.settings.store_base_materials:
			var materials: Dictionary = {}
			for brush in brushes:
				materials.merge(brush.materials, false)
			for surface_index in range(csg_mesh.get_surface_count()):
				var surface_name := csg_mesh.surface_get_name(surface_index)
				var material: MapperMaterial = materials.get(surface_name, null)
				if material and material.override:
					instance.set_surface_override_material(surface_index, material.override)

		instance.cast_shadow = int(entity.is_casting_shadow())

	if csg_shape:
		var instance := CollisionShape3D.new()
		instance.position = entity.center
		add_global_child(instance, node, entity.factory.settings)
		instance.shape = csg_shape
		has_children = true

	if csg_occluder:
		var instance := OccluderInstance3D.new()
		instance.position = entity.center
		add_global_child(instance, node, entity.factory.settings)
		instance.occluder = csg_occluder
		has_children = true

	if has_children:
		if ClassDB.is_parent_class(node_class, "RigidBody3D"):
			var mass := entity.get_mass(use_approximate_mass)
			if mass > 0.0: node.set("mass", mass)
		entity.node_properties.erase("position")
		entity.node_properties.erase("rotation")
		entity.node_properties.erase("scale")
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
