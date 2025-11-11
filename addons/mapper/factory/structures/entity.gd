class_name MapperEntity

var properties: Dictionary
var brushes: Array[MapperBrush]

var mesh: ArrayMesh
var concave_shape: ConcavePolygonShape3D
var convex_shape: ConvexPolygonShape3D
var shape: Shape3D
var occluder: ArrayOccluder3D
var center: Vector3 # aabb center and not origin
var aabb: AABB

var node: Node # only valid after all build scripts executed
var node_properties: Dictionary # stores converted properties
var node_groups: PackedStringArray # stores future node groups
var node_paths: Array[Array] # gets filled automatically after binding
var signals: Array[Array] # gets filled automatically after binding
var parent: MapperEntity:
	set(value):
		var hierarchy := { self: true }
		var current_parent: MapperEntity = value
		var is_valid_parent := true
		while current_parent:
			if hierarchy.size() > factory.settings.MAX_ENTITY_PARENT_DEPTH:
				push_warning("Error setting entity parent, hierarchy is too deep.")
				is_valid_parent = false
				break
			elif current_parent in hierarchy:
				push_warning("Error setting entity parent, circular reference detected.")
				is_valid_parent = false
				break
			hierarchy[current_parent] = true
			current_parent = current_parent.parent
		if is_valid_parent:
			parent = value

var metadata: Dictionary
var factory: MapperFactory


func get_property(method: StringName, property: StringName, default: Variant) -> Variant:
	var value: Variant = properties.get(property, null)
	if value == null:
		return default
	var converted_property: Variant = null
	var game_property_converter := factory.game_property_converter
	if game_property_converter.has_method(method):
		converted_property = game_property_converter.call(method, value)
	else:
		push_warning("Error converting property, method '%s' not found." % [method])
	if converted_property != null:
		return converted_property
	return default


func bind_property(method: StringName, property: StringName, node_property: StringName) -> void:
	var value: Variant = get_property(method, property, null)
	if value != null:
		node_properties[node_property] = value


func bind_node_path_property(property: StringName, target_source_property: StringName, node_property: StringName, classname: String = "*") -> void:
	var parameters: Array[Variant] = [property, target_source_property, node_property, classname, true]
	if not parameters in node_paths:
		node_paths.append(parameters)


func bind_node_path_array_property(property: StringName, target_source_property: StringName, node_property: StringName, classname: String = "*") -> void:
	var parameters: Array[Variant] = [property, target_source_property, node_property, classname, false]
	if not parameters in node_paths:
		node_paths.append(parameters)


func bind_signal_property(property: StringName, target_source_property: StringName, signal_name: StringName, method: StringName, classname: String = "*", flags: int = 0) -> void:
	var parameters: Array[Variant] = [property, target_source_property, signal_name, method, classname, flags]
	if not parameters in signals:
		signals.append(parameters)


func get_string_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_string", property, default)


func get_variant_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_variant", property, default)


func get_classname_property(default: Variant = null) -> Variant:
	var classname_property := factory.settings.classname_property
	if classname_property in properties:
		var classname: String = properties[classname_property]
		return classname.strip_edges()
	return default


func get_origin_property(default: Variant = null) -> Variant:
	return get_property("convert_origin", factory.settings.origin_property, default)


func get_angle_property(default: Variant = null) -> Variant:
	return get_property("convert_angle", factory.settings.angle_property, default)


func get_angles_property(default: Variant = null, rotation_mode: String = "PYR") -> Variant:
	return get_property("convert_angles_" + rotation_mode, factory.settings.angles_property, default)


func get_mangle_property(default: Variant = null, rotation_mode: String = "PYR") -> Variant:
	return get_property("convert_mangle_" + rotation_mode, factory.settings.mangle_property, default)


func get_unit_property(property: StringName, default: Variant = null, convert_default: bool = true) -> Variant:
	if convert_default:
		var default_string: String = ""
		if typeof(default) in [TYPE_STRING, TYPE_STRING_NAME, TYPE_INT, TYPE_FLOAT]:
			default_string = str(default)
		var converted_default: Variant = factory.game_property_converter.call("convert_unit", default_string)
		return get_property("convert_unit", property, converted_default)
	return get_property("convert_unit", property, default)


func get_color_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_color", property, default)


func get_bool_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_bool", property, default)


func get_int_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_int", property, default)


func get_vector2i_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_vector2i", property, default)


func get_vector3i_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_vector3i", property, default)


func get_vector4i_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_vector4i", property, default)


func get_float_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_float", property, default)


func get_vector2_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_vector2", property, default)


func get_vector3_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_vector3", property, default)


func get_vector4_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_vector4", property, default)


func get_sound_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_sound", property, default)


func get_map_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_map", property, default)


func get_mdl_property(property: StringName, default: Variant = null) -> Variant:
	return get_property("convert_mdl", property, default)


func bind_string_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_string", property, node_property)


func bind_variant_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_variant", property, node_property)


func bind_origin_property(node_property: StringName) -> void:
	bind_property("convert_origin", factory.settings.origin_property, node_property)


func bind_angle_property(node_property: StringName) -> void:
	bind_property("convert_angle", factory.settings.angle_property, node_property)


func bind_angles_property(node_property: StringName, rotation_mode: String = "PYR") -> void:
	bind_property("convert_angles_" + rotation_mode, factory.settings.angles_property, node_property)


func bind_mangle_property(node_property: StringName, rotation_mode: String = "PYR") -> void:
	bind_property("convert_mangle_" + rotation_mode, factory.settings.mangle_property, node_property)


func bind_unit_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_unit", property, node_property)


func bind_color_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_color", property, node_property)


func bind_bool_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_bool", property, node_property)


func bind_int_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_int", property, node_property)


func bind_vector2i_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_vector2i", property, node_property)


func bind_vector3i_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_vector3i", property, node_property)


func bind_vector4i_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_vector4i", property, node_property)


func bind_float_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_float", property, node_property)


func bind_vector2_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_vector2", property, node_property)


func bind_vector3_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_vector3", property, node_property)


func bind_vector4_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_vector4", property, node_property)


func bind_sound_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_sound", property, node_property)


func bind_map_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_map", property, node_property)


func bind_mdl_property(property: StringName, node_property: StringName) -> void:
	bind_property("convert_mdl", property, node_property)


func get_lightmap_scale_property(default: Variant = null) -> Variant:
	if factory.settings.lightmap_scale_property_enabled:
		var lightmap_scale: Variant = get_float_property(factory.settings.lightmap_scale_property, null)
		if lightmap_scale != null:
			return clampf(lightmap_scale, 0.0625, 16.0)
		elif typeof(default) in [TYPE_FLOAT, TYPE_INT]:
			return clampf(float(default), 0.0625, 16.0)
		else:
			return default
	return default


func is_smooth_shaded() -> bool:
	if factory.settings.smooth_shading_property_enabled:
		return bool(get_float_property(factory.settings.smooth_shading_property, false))
	return false


func is_casting_shadow() -> bool:
	if factory.settings.cast_shadow_property_enabled:
		return bool(get_float_property(factory.settings.cast_shadow_property, true))
	return false


func is_decal() -> bool:
	return bool(aabb.has_volume() and brushes.size() == 1 and brushes[0].is_uniform())


func get_surface_area(from_mesh: bool = true) -> float:
	var area: float = 0.0
	for brush in brushes:
		area += brush.get_surface_area(from_mesh)
	return area


func get_matching_surfaces(surfaces: PackedStringArray) -> PackedStringArray:
	var matching_surfaces := PackedStringArray()
	var matching_brush_surfaces: Dictionary = {}
	for brush in brushes:
		for matching_surface in brush.get_matching_surfaces(surfaces):
			matching_brush_surfaces[matching_surface] = true
	for matching_surface in matching_brush_surfaces:
		matching_surfaces.append(matching_surface)
	return matching_surfaces


func get_surfaces_area(surfaces: PackedStringArray) -> float:
	var area: float = 0.0
	for brush in brushes:
		area += brush.get_surfaces_area(surfaces)
	return area


func get_volume(from_aabb: bool = true) -> float:
	var volume: float = 0.0
	for brush in brushes:
		volume += brush.get_volume(from_aabb)
	return volume


func get_mass(from_aabb: bool = true) -> float:
	var mass: float = 0.0
	for brush in brushes:
		mass += brush.get_mass(from_aabb)
	return mass


func generate_surface_distribution(surfaces: PackedStringArray, density: float, min_floor_angle: float = 0.0, max_floor_angle: float = 45.0, even_distribution: bool = false, world_space: bool = false, seed: int = 0, _use_map_basis: bool = true) -> PackedVector3Array:
	var transform_array := PackedVector3Array()
	var mutex := Mutex.new()

	var populate_brushes := func(thread_index: int) -> void:
		var brush := brushes[thread_index]
		var brush_transform_array := brush.generate_surface_distribution(surfaces, density, min_floor_angle, max_floor_angle, even_distribution, world_space, seed + thread_index, _use_map_basis)
		if not world_space:
			for index in range(3, brush_transform_array.size(), 4):
				brush_transform_array[index] += brush.center - center
		mutex.lock()
		transform_array.append_array(brush_transform_array)
		mutex.unlock()

	if not factory.settings.force_deterministic and factory.settings.use_threads:
		var group_task := WorkerThreadPool.add_group_task(populate_brushes, brushes.size(), 4, true)
		WorkerThreadPool.wait_for_group_task_completion(group_task)
	else:
		for index in range(brushes.size()):
			populate_brushes.call(index)

	return transform_array


func generate_volume_distribution(density: float, min_penetration: float = 0.0, max_penetration: float = INF, basis: Basis = Basis.IDENTITY, world_space: bool = false, seed: int = 0, _use_map_basis: bool = true) -> PackedVector3Array:
	var transform_array := PackedVector3Array()
	var mutex := Mutex.new()

	var populate_brushes := func(thread_index: int) -> void:
		var brush := brushes[thread_index]
		var brush_transform_array := brush.generate_volume_distribution(density, min_penetration, max_penetration, basis, world_space, seed + thread_index, _use_map_basis)
		if not world_space:
			for index in range(3, brush_transform_array.size(), 4):
				brush_transform_array[index] += brush.center - center
		mutex.lock()
		transform_array.append_array(brush_transform_array)
		mutex.unlock()

	if not factory.settings.force_deterministic and factory.settings.use_threads:
		var group_task := WorkerThreadPool.add_group_task(populate_brushes, brushes.size(), 4, true)
		WorkerThreadPool.wait_for_group_task_completion(group_task)
	else:
		for index in range(brushes.size()):
			populate_brushes.call(index)

	return transform_array
