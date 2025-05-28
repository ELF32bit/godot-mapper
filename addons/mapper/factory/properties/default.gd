class_name MapperPropertyConverter

var settings: MapperSettings
var game_loader: MapperLoader


func convert_string(line: String) -> Variant:
	return line


func convert_origin(line: String) -> Variant:
	var numbers := line.split_floats(" ", false)
	if numbers.size() < 3:
		return null
	return settings.basis * Vector3(numbers[0], numbers[1], numbers[2]) * (1.0 / settings.unit_size)


func convert_angle(line: String) -> Variant:
	if line.is_valid_float():
		var angle := line.to_float()
		var forward_rotation := Quaternion(Vector3.FORWARD, settings.basis.x)
		if angle == -1:
			return (Quaternion(settings.basis.x, settings.basis.z) * forward_rotation).get_euler()
		if angle == -2:
			return (Quaternion(settings.basis.x, -settings.basis.z) * forward_rotation).get_euler()
		return (Quaternion(settings.basis.z, deg_to_rad(angle)) * forward_rotation).get_euler()
	return null


func convert_angles(line: String) -> Variant:
	var numbers := line.split_floats(" ", false)
	if numbers.size() < 3:
		return null
	var x := Quaternion(settings.basis.x, deg_to_rad(numbers[2]))
	var y := Quaternion(settings.basis.z, deg_to_rad(numbers[1]))
	var z := Quaternion(settings.basis.y, deg_to_rad(numbers[0]))
	return (y * z * x * Quaternion(Vector3.FORWARD, settings.basis.x)).get_euler()


func convert_unit(line: String) -> Variant:
	if line.is_valid_float():
		return line.to_float() * (1.0 / settings.unit_size)
	return null


func convert_axis(line: String) -> Variant:
	var numbers := line.split_floats(" ", false)
	if numbers.size() < 3:
		return null
	return (settings.basis * Vector3(numbers[0], numbers[1], numbers[2])).normalized()


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
	elif line.is_valid_int():
		return bool(line.to_int())
	elif line.is_valid_float():
		return bool(line.to_float())
	return null


func convert_int(line: String) -> Variant:
	if line.is_valid_int():
		return line.to_int()
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


func convert_float(line: String) -> Variant:
	if line.is_valid_float():
		return line.to_float()
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


func convert_sound(line: String) -> Variant:
	return game_loader.load_sound(settings.game_sounds_directory.path_join(line))


func convert_map(line: String) -> Variant:
	return game_loader.load_map(settings.game_maps_directory.path_join(line))


func convert_mdl(line: String) -> Variant:
	return game_loader.load_mdl(settings.game_mdls_directory.path_join(line))
