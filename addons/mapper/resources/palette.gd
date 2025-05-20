class_name MapperPaletteResource
extends Resource

@export var colors: PackedColorArray


func _init(colors: PackedColorArray = PackedColorArray()) -> void:
	self.colors = colors.duplicate()
	self.colors.resize(256)


static func create_default() -> MapperPaletteResource:
	return MapperPaletteResource.new(PackedColorArray([Color8(0, 0, 0), Color8(15, 15, 15), Color8(31, 31, 31), Color8(47, 47, 47), Color8(63, 63, 63), Color8(75, 75, 75), Color8(91, 91, 91), Color8(107, 107, 107), Color8(123, 123, 123), Color8(139, 139, 139), Color8(155, 155, 155), Color8(171, 171, 171), Color8(187, 187, 187), Color8(203, 203, 203), Color8(219, 219, 219), Color8(235, 235, 235), Color8(15, 11, 7), Color8(23, 15, 11), Color8(31, 23, 11), Color8(39, 27, 15), Color8(47, 35, 19), Color8(55, 43, 23), Color8(63, 47, 23), Color8(75, 55, 27), Color8(83, 59, 27), Color8(91, 67, 31), Color8(99, 75, 31), Color8(107, 83, 31), Color8(115, 87, 31), Color8(123, 95, 35), Color8(131, 103, 35), Color8(143, 111, 35), Color8(11, 11, 15), Color8(19, 19, 27), Color8(27, 27, 39), Color8(39, 39, 51), Color8(47, 47, 63), Color8(55, 55, 75), Color8(63, 63, 87), Color8(71, 71, 103), Color8(79, 79, 115), Color8(91, 91, 127), Color8(99, 99, 139), Color8(107, 107, 151), Color8(115, 115, 163), Color8(123, 123, 175), Color8(131, 131, 187), Color8(139, 139, 203), Color8(0, 0, 0), Color8(7, 7, 0), Color8(11, 11, 0), Color8(19, 19, 0), Color8(27, 27, 0), Color8(35, 35, 0), Color8(43, 43, 7), Color8(47, 47, 7), Color8(55, 55, 7), Color8(63, 63, 7), Color8(71, 71, 7), Color8(75, 75, 11), Color8(83, 83, 11), Color8(91, 91, 11), Color8(99, 99, 11), Color8(107, 107, 15), Color8(7, 0, 0), Color8(15, 0, 0), Color8(23, 0, 0), Color8(31, 0, 0), Color8(39, 0, 0), Color8(47, 0, 0), Color8(55, 0, 0), Color8(63, 0, 0), Color8(71, 0, 0), Color8(79, 0, 0), Color8(87, 0, 0), Color8(95, 0, 0), Color8(103, 0, 0), Color8(111, 0, 0), Color8(119, 0, 0), Color8(127, 0, 0), Color8(19, 19, 0), Color8(27, 27, 0), Color8(35, 35, 0), Color8(47, 43, 0), Color8(55, 47, 0), Color8(67, 55, 0), Color8(75, 59, 7), Color8(87, 67, 7), Color8(95, 71, 7), Color8(107, 75, 11), Color8(119, 83, 15), Color8(131, 87, 19), Color8(139, 91, 19), Color8(151, 95, 27), Color8(163, 99, 31), Color8(175, 103, 35), Color8(35, 19, 7), Color8(47, 23, 11), Color8(59, 31, 15), Color8(75, 35, 19), Color8(87, 43, 23), Color8(99, 47, 31), Color8(115, 55, 35), Color8(127, 59, 43), Color8(143, 67, 51), Color8(159, 79, 51), Color8(175, 99, 47), Color8(191, 119, 47), Color8(207, 143, 43), Color8(223, 171, 39), Color8(239, 203, 31), Color8(255, 243, 27), Color8(11, 7, 0), Color8(27, 19, 0), Color8(43, 35, 15), Color8(55, 43, 19), Color8(71, 51, 27), Color8(83, 55, 35), Color8(99, 63, 43), Color8(111, 71, 51), Color8(127, 83, 63), Color8(139, 95, 71), Color8(155, 107, 83), Color8(167, 123, 95), Color8(183, 135, 107), Color8(195, 147, 123), Color8(211, 163, 139), Color8(227, 179, 151), Color8(171, 139, 163), Color8(159, 127, 151), Color8(147, 115, 135), Color8(139, 103, 123), Color8(127, 91, 111), Color8(119, 83, 99), Color8(107, 75, 87), Color8(95, 63, 75), Color8(87, 55, 67), Color8(75, 47, 55), Color8(67, 39, 47), Color8(55, 31, 35), Color8(43, 23, 27), Color8(35, 19, 19), Color8(23, 11, 11), Color8(15, 7, 7), Color8(187, 115, 159), Color8(175, 107, 143), Color8(163, 95, 131), Color8(151, 87, 119), Color8(139, 79, 107), Color8(127, 75, 95), Color8(115, 67, 83), Color8(107, 59, 75), Color8(95, 51, 63), Color8(83, 43, 55), Color8(71, 35, 43), Color8(59, 31, 35), Color8(47, 23, 27), Color8(35, 19, 19), Color8(23, 11, 11), Color8(15, 7, 7), Color8(219, 195, 187), Color8(203, 179, 167), Color8(191, 163, 155), Color8(175, 151, 139), Color8(163, 135, 123), Color8(151, 123, 111), Color8(135, 111, 95), Color8(123, 99, 83), Color8(107, 87, 71), Color8(95, 75, 59), Color8(83, 63, 51), Color8(67, 51, 39), Color8(55, 43, 31), Color8(39, 31, 23), Color8(27, 19, 15), Color8(15, 11, 7), Color8(111, 131, 123), Color8(103, 123, 111), Color8(95, 115, 103), Color8(87, 107, 95), Color8(79, 99, 87), Color8(71, 91, 79), Color8(63, 83, 71), Color8(55, 75, 63), Color8(47, 67, 55), Color8(43, 59, 47), Color8(35, 51, 39), Color8(31, 43, 31), Color8(23, 35, 23), Color8(15, 27, 19), Color8(11, 19, 11), Color8(7, 11, 7), Color8(255, 243, 27), Color8(239, 223, 23), Color8(219, 203, 19), Color8(203, 183, 15), Color8(187, 167, 15), Color8(171, 151, 11), Color8(155, 131, 7), Color8(139, 115, 7), Color8(123, 99, 7), Color8(107, 83, 0), Color8(91, 71, 0), Color8(75, 55, 0), Color8(59, 43, 0), Color8(43, 31, 0), Color8(27, 15, 0), Color8(11, 7, 0), Color8(0, 0, 255), Color8(11, 11, 239), Color8(19, 19, 223), Color8(27, 27, 207), Color8(35, 35, 191), Color8(43, 43, 175), Color8(47, 47, 159), Color8(47, 47, 143), Color8(47, 47, 127), Color8(47, 47, 111), Color8(47, 47, 95), Color8(43, 43, 79), Color8(35, 35, 63), Color8(27, 27, 47), Color8(19, 19, 31), Color8(11, 11, 15), Color8(43, 0, 0), Color8(59, 0, 0), Color8(75, 7, 0), Color8(95, 7, 0), Color8(111, 15, 0), Color8(127, 23, 7), Color8(147, 31, 7), Color8(163, 39, 11), Color8(183, 51, 15), Color8(195, 75, 27), Color8(207, 99, 43), Color8(219, 127, 59), Color8(227, 151, 79), Color8(231, 171, 95), Color8(239, 191, 119), Color8(247, 211, 139), Color8(167, 123, 59), Color8(183, 155, 55), Color8(199, 195, 55), Color8(231, 227, 87), Color8(127, 191, 255), Color8(171, 231, 255), Color8(215, 255, 255), Color8(103, 0, 0), Color8(139, 0, 0), Color8(179, 0, 0), Color8(215, 0, 0), Color8(255, 0, 0), Color8(255, 243, 147), Color8(255, 247, 199), Color8(255, 255, 255), Color8(159, 91, 83)]))


static func create_from_color_array(from: PackedColorArray) -> MapperPaletteResource:
	if from.size() != 256:
		push_error("Invalid array size, must be exactly 256 colors.")
		return null

	return MapperPaletteResource.new(from)


static func create_from_byte_array(from: PackedByteArray) -> MapperPaletteResource:
	if from.size() != 256 * 3:
		push_error("Invalid array size, must be exactly 768 bytes.")
		return null

	var colors: PackedColorArray
	colors.resize(256)

	for index in range(colors.size()):
		colors[index] = Color8(from[index * 3 + 0], from[index * 3 + 1], from[index * 3 + 2])

	return MapperPaletteResource.new(colors)


static func load_from_file(path: String) -> MapperPaletteResource:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return null

	if file.get_length() != 256 * 3:
		push_error("Invalid palette file, must be exactly 768 bytes.")
		return null

	return create_from_byte_array(file.get_buffer(256 * 3))
