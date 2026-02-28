class_name MapperPropertyConverter

var settings: MapperSettings
var game_loader: MapperLoader


func convert_string(line: String) -> Variant:
	return line


func convert_variant(line: String) -> Variant:
	var result := str_to_var(line)
	if result != null:
		return result
	elif line.strip_edges() == "null":
		return null
	return line


func convert_origin(line: String) -> Variant:
	var numbers := line.split_floats(" ", false)
	if numbers.size() < 3:
		return null
	return settings.basis * Vector3(numbers[0], numbers[1], numbers[2]) * (1.0 / settings.unit_size)


func convert_angle(line: String) -> Variant:
	var line_strip := line.strip_edges()
	if line_strip.is_valid_float():
		var angle := line_strip.to_float()
		var up := settings.get_up_vector()
		var forward := settings.get_forward_vector()
		var forward_rotation := settings.get_forward_rotation()
		if angle == -1:
			return (Quaternion(forward, up) * forward_rotation).get_euler()
		if angle == -2:
			return (Quaternion(forward, -up) * forward_rotation).get_euler()
		return (Quaternion(up, deg_to_rad(angle)) * forward_rotation).get_euler()
	return null


func convert_angles(line: String, rotation_mode: String = "PYR") -> Variant:
	var numbers := line.split_floats(" ", false)
	if numbers.size() < 3:
		return null
	var up := settings.get_up_vector()
	var forward := settings.get_forward_vector()
	var forward_rotation := settings.get_forward_rotation()
	var right := settings.get_right_vector()

	var pitch_index := rotation_mode.findn("P")
	var yaw_index := rotation_mode.findn("Y")
	var roll_index := rotation_mode.findn("R")
	var rotations := PackedFloat64Array([0.0, 0.0, 0.0])
	rotations[0] = numbers[pitch_index] * (1.0 if rotation_mode[pitch_index] == "P" else -1.0)
	rotations[1] = numbers[yaw_index] * (1.0 if rotation_mode[yaw_index] == "Y" else -1.0)
	rotations[2] = numbers[roll_index] * (1.0 if rotation_mode[roll_index] == "R" else -1.0)

	var pitch := Quaternion(-right, deg_to_rad(rotations[0]))
	var yaw := Quaternion(up, deg_to_rad(rotations[1]))
	var roll := Quaternion(forward, deg_to_rad(rotations[2]))
	return (yaw * pitch * roll * forward_rotation).get_euler()


func convert_angles_PYR(line: String) -> Variant:
	return convert_angles(line, "PYR")


func convert_angles_YpR(line: String) -> Variant:
	return convert_angles(line, "YpR")


func convert_mangle(line: String, rotation_mode: String = "PYR") -> Variant:
	return convert_angles(line, rotation_mode)


func convert_mangle_PYR(line: String) -> Variant:
	return convert_mangle(line, "PYR")


func convert_mangle_YpR(line: String) -> Variant:
	return convert_mangle(line, "YpR")


func convert_unit(line: String) -> Variant:
	var line_strip := line.strip_edges()
	if line_strip.is_valid_float():
		return line_strip.to_float() * (1.0 / settings.unit_size)
	return null


func convert_color(line: String) -> Variant:
	var numbers := line.split_floats(" ", false)
	if numbers.size() < 3:
		return null
	if numbers[0] > 1.0 or numbers[1] > 1.0 or numbers[2] > 1.0:
		return Color(numbers[0] / 255.0, numbers[1] / 255.0, numbers[2] / 255.0, 1.0)
	return Color(numbers[0], numbers[1], numbers[2], 1.0)


func convert_bool(line: String) -> Variant:
	var line_strip := line.strip_edges()
	if line_strip.matchn("true"):
		return true
	elif line_strip.matchn("false"):
		return false
	elif line_strip.is_valid_int():
		return bool(line_strip.to_int())
	elif line_strip.is_valid_float():
		return bool(line_strip.to_float())
	return null


func convert_int(line: String) -> Variant:
	var line_strip := line.strip_edges()
	if line_strip.is_valid_int():
		return line_strip.to_int()
	return null


func convert_vector2i(line: String) -> Variant:
	var numbers := line.split_floats(" ", false)
	if numbers.size() < 2:
		return null
	return Vector2i(int(numbers[0]), int(numbers[1]))


func convert_vector3i(line: String) -> Variant:
	var numbers := line.split_floats(" ", false)
	if numbers.size() < 3:
		return null
	return Vector3i(int(numbers[0]), int(numbers[1]), int(numbers[2]))


func convert_vector4i(line: String) -> Variant:
	var numbers := line.split_floats(" ", false)
	if numbers.size() < 4:
		return null
	return Vector4i(int(numbers[0]), int(numbers[1]), int(numbers[2]), int(numbers[3]))


func convert_float(line: String) -> Variant:
	var line_strip := line.strip_edges()
	if line_strip.is_valid_float():
		return line_strip.to_float()
	return null


func convert_vector2(line: String) -> Variant:
	var numbers := line.split_floats(" ", false)
	if numbers.size() < 2:
		return null
	return Vector2(numbers[0], numbers[1])


func convert_vector3(line: String) -> Variant:
	var numbers := line.split_floats(" ", false)
	if numbers.size() < 3:
		return null
	return Vector3(numbers[0], numbers[1], numbers[2])


func convert_vector4(line: String) -> Variant:
	var numbers := line.split_floats(" ", false)
	if numbers.size() < 4:
		return null
	return Vector4(numbers[0], numbers[1], numbers[2], numbers[3])


func convert_sound(line: String) -> Variant:
	return game_loader.load_sound(settings.game_sounds_directory.path_join(line))


func convert_map(line: String) -> Variant:
	return game_loader.load_map_raw(settings.game_maps_directory.path_join(line), true)


func convert_mdl(line: String) -> Variant:
	if settings.mdls_palette == null:
		return game_loader.load_mdl(settings.game_mdls_directory.path_join(line))
	return game_loader.load_mdl_raw(settings.game_mdls_directory.path_join(line), settings.mdls_palette)
