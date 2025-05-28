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
var node_groups: PackedStringArray
var signals: Array[Array] # gets filled automatically after binding
var node_paths: Array[Array] # gets filled automatically after binding
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

var factory: MapperFactory


func _get_property(method: StringName, property: StringName, default: Variant) -> Variant:
	var value: Variant = properties.get(property, null)
	if value == null:
		return default
	var converted_property: Variant = factory.game_property_converter.call(method, value)
	if converted_property != null:
		return converted_property
	return default


func _bind_property(type: StringName, property: StringName, node_property: StringName) -> void:
	var value: Variant = _get_property(type, property, null)
	if value != null:
		node_properties[node_property] = value


func bind_signal_property(property: StringName, target_source_property: StringName, signal_name: StringName, method: StringName, classname: String = "*", flags: int = 0) -> void:
	var parameters: Array[Variant] = [property, target_source_property, signal_name, method, classname, flags]
	if not parameters in signals:
		signals.append(parameters)


func bind_node_path_property(property: StringName, target_source_property: StringName, node_property: StringName, classname: String = "*") -> void:
	var parameters: Array[Variant] = [property, target_source_property, node_property, classname]
	if not parameters in node_paths:
		node_paths.append([property, target_source_property, node_property, classname, true])


func bind_node_path_array_property(property: StringName, target_source_property: StringName, node_property: StringName, classname: String = "*") -> void:
	var parameters: Array[Variant] = [property, target_source_property, node_property, classname]
	if not parameters in node_paths:
		node_paths.append([property, target_source_property, node_property, classname, false])


func get_string_property(property: StringName, default: Variant = null) -> Variant:
	return _get_property("convert_string", property, default)


func get_origin_property(default: Variant = null) -> Variant:
	return _get_property("convert_origin", factory.settings.origin_property, default)


func get_angle_property(default: Variant = null) -> Variant:
	return _get_property("convert_angle", factory.settings.angle_property, default)


func get_angles_property(default: Variant = null) -> Variant:
	return _get_property("convert_angles", factory.settings.angles_property, default)


func get_mangle_property(default: Variant = null) -> Variant:
	return _get_property("convert_angles", factory.settings.mangle_property, default)


func get_unit_property(property: StringName, default: Variant = null, convert_default: bool = true) -> Variant:
	if convert_default:
		var default_string: String = ""
		if typeof(default) in [TYPE_STRING, TYPE_STRING_NAME, TYPE_INT, TYPE_FLOAT]:
			default_string = str(default)
		var converted_default: Variant = factory.game_property_converter.call("convert_unit", default_string)
		return _get_property("convert_unit", property, converted_default)
	return _get_property("convert_unit", property, default)


func get_axis_property(property: StringName, default: Variant = null) -> Variant:
	return _get_property("convert_axis", property, default)


func get_color_property(property: StringName, default: Variant = null) -> Variant:
	return _get_property("convert_color", property, default)


func get_bool_property(property: StringName, default: Variant = null) -> Variant:
	return _get_property("convert_bool", property, default)


func get_int_property(property: StringName, default: Variant = null) -> Variant:
	return _get_property("convert_int", property, default)


func get_vector2i_property(property: StringName, default: Variant = null) -> Variant:
	return _get_property("convert_vector2i", property, default)


func get_vector3i_property(property: StringName, default: Variant = null) -> Variant:
	return _get_property("convert_vector3i", property, default)


func get_float_property(property: StringName, default: Variant = null) -> Variant:
	return _get_property("convert_float", property, default)


func get_vector2_property(property: StringName, default: Variant = null) -> Variant:
	return _get_property("convert_vector2", property, default)


func get_vector3_property(property: StringName, default: Variant = null) -> Variant:
	return _get_property("convert_vector3", property, default)


func get_sound_property(property: StringName, default: Variant = null) -> Variant:
	return _get_property("convert_sound", property, default)


func get_map_property(property: StringName, default: Variant = null) -> Variant:
	return _get_property("convert_map", property, default)


func get_mdl_property(property: StringName, default: Variant = null) -> Variant:
	return _get_property("convert_mdl", property, default)


func bind_string_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_string", property, node_property)


func bind_origin_property(node_property: StringName) -> void:
	_bind_property("convert_origin", factory.settings.origin_property, node_property)


func bind_angle_property(node_property: StringName) -> void:
	_bind_property("convert_angle", factory.settings.angle_property, node_property)


func bind_angles_property(node_property: StringName) -> void:
	_bind_property("convert_angles", factory.settings.angles_property, node_property)


func bind_mangle_property(node_property: StringName) -> void:
	_bind_property("convert_angles", factory.settings.mangle_property, node_property)


func bind_unit_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_unit", property, node_property)


func bind_axis_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_axis", property, node_property)


func bind_color_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_color", property, node_property)


func bind_bool_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_bool", property, node_property)


func bind_int_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_int", property, node_property)


func bind_vector2i_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_vector2i", property, node_property)


func bind_vector3i_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_vector3i", property, node_property)


func bind_float_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_float", property, node_property)


func bind_vector2_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_vector2", property, node_property)


func bind_vector3_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_vector3", property, node_property)


func bind_sound_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_sound", property, node_property)


func bind_map_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_map", property, node_property)


func bind_mdl_property(property: StringName, node_property: StringName) -> void:
	_bind_property("convert_mdl", property, node_property)


func is_smooth_shaded() -> bool:
	return bool(get_float_property(factory.settings.smooth_shading_property, false) and factory.settings.smooth_shading_property_enabled)


func is_casting_shadow() -> bool:
	return bool(get_float_property(factory.settings.cast_shadow_property, true) and factory.settings.cast_shadow_property_enabled)


func is_decal() -> bool:
	return bool(aabb.has_volume() and brushes.size() == 1 and brushes[0].is_uniform())


func generate_surface_distribution(surfaces: PackedStringArray, density: float, spread: float = 0.0, min_scale: float = 1.0, max_scale: float = 1.0, min_floor_angle: float = 0.0, max_floor_angle: float = 45.0, even_distribution: bool = false, random_rotation: bool = true, world_space: bool = false, seed: int = 0) -> PackedVector3Array:
	var transform_array := PackedVector3Array()
	var mutex := Mutex.new()

	var populate_brushes := func(thread_index: int) -> void:
		var brush := brushes[thread_index]
		var brush_transform_array := brush.generate_surface_distribution(surfaces, density, 0.0, min_scale, max_scale, min_floor_angle, max_floor_angle, even_distribution, random_rotation, world_space, seed + thread_index)
		if not world_space:
			for index in range(3, brush_transform_array.size(), 4):
				brush_transform_array[index] += brush.center - center
		mutex.lock()
		transform_array.append_array(brush_transform_array)
		mutex.unlock()

	if not factory.settings.force_deterministic and factory.settings.use_threads:
		var group_task := WorkerThreadPool.add_group_task(populate_brushes, brushes.size(), -1, true)
		WorkerThreadPool.wait_for_group_task_completion(group_task)
	else:
		for index in range(brushes.size()):
			populate_brushes.call(index)

	if spread > 0.0:
		return MapperUtilities.spread_transform_array(transform_array, spread)

	return transform_array


func generate_volume_distribution(density: float, spread: float = 0.0, min_scale: float = 1.0, max_scale: float = 1.0, min_depth: float = 0.0, max_depth: float = 1.0, random_rotation: bool = true, world_space: bool = false, seed: int = 0) -> PackedVector3Array:
	var transform_array := PackedVector3Array()
	var mutex := Mutex.new()

	var populate_brushes := func(thread_index: int) -> void:
		var brush := brushes[thread_index]
		var brush_transform_array := brush.generate_volume_distribution(density, 0.0, min_scale, max_scale, min_depth, max_depth, random_rotation, world_space, seed + thread_index)
		if not world_space:
			for index in range(3, brush_transform_array.size(), 4):
				brush_transform_array[index] += brush.center - center
		mutex.lock()
		transform_array.append_array(brush_transform_array)
		mutex.unlock()

	if not factory.settings.force_deterministic and factory.settings.use_threads:
		var group_task := WorkerThreadPool.add_group_task(populate_brushes, brushes.size(), -1, true)
		WorkerThreadPool.wait_for_group_task_completion(group_task)
	else:
		for index in range(brushes.size()):
			populate_brushes.call(index)

	if spread > 0.0:
		return MapperUtilities.spread_transform_array(transform_array, spread)

	return transform_array
