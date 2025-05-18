class_name MapperWadResource
extends Resource

@export var textures: Dictionary


func _init(textures: Dictionary = {}) -> void:
	self.textures = textures


static func load_from_file(path: String, palette: MapperPaletteResource = null, use_threads: bool = false) -> MapperWadResource:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return null

	# reading WAD header
	var magic := file.get_buffer(4).get_string_from_ascii()

	# validating WAD magic
	if magic != "WAD2" and magic != "WAD3":
		push_error("Invalid WAD magic.")
		return null
	var number_of_entries := file.get_32()
	var directory_offset := file.get_32()

	# reading WAD entry list
	var texture1_positions: PackedInt32Array
	var texture2_positions: PackedInt32Array
	var texture2_disk_sizes: PackedInt32Array
	var palette_position: Variant = null

	file.seek(directory_offset)

	for index in range(number_of_entries):
		var position := file.get_32()
		var disk_size := file.get_32()
		var memory_size := file.get_32()
		var type := file.get_8()
		var compression := file.get_8()
		var padding := file.get_16()
		var name := file.get_buffer(16)

		match type:
			0x44:
				texture1_positions.append(position)
			0x43:
				texture2_positions.append(position)
				texture2_disk_sizes.append(disk_size)
			0x40:
				if palette_position == null and magic == "WAD2":
					palette_position = position

	# using provided palette or reading it from WAD
	var default_palette: MapperPaletteResource = null

	if palette:
		default_palette = palette
	elif palette_position != null:
		file.seek(palette_position)
		default_palette = MapperPaletteResource.create_from_byte_array(file.get_buffer(256 * 3))
	else:
		default_palette = MapperPaletteResource.create_default()

	# filling WAD textures
	var wad := MapperWadResource.new()
	var mutex := Mutex.new()

	var extract_texture := func(thread_file: FileAccess, thread_index: int, position: int, palette: MapperPaletteResource) -> void:
		thread_file.seek(position)

		var name := thread_file.get_buffer(16).get_string_from_ascii()
		var width := thread_file.get_32()
		var height := thread_file.get_32()

		if width == 0 or height == 0 or width > 4096 or height > 4096:
			push_error("Texture '%s' has invalid size: %sx%s." % [name, width, height])
			return

		var mip_positions: PackedInt32Array
		mip_positions.resize(4)

		mip_positions[0] = thread_file.get_32()
		mip_positions[1] = thread_file.get_32()
		mip_positions[2] = thread_file.get_32()
		mip_positions[3] = thread_file.get_32()

		var indexed_colors := thread_file.get_buffer(width * height)

		var colors_rgb: PackedByteArray
		colors_rgb.resize(indexed_colors.size() * 3)
		var colors_rgba: PackedByteArray
		var fullbright_colors_rgb: PackedByteArray
		if magic == "WAD2":
			colors_rgba.resize(indexed_colors.size() * 4)
			fullbright_colors_rgb.resize(indexed_colors.size() * 3)

		var has_alpha := false
		var has_fullbright_colors := false
		for index in range(indexed_colors.size()):
			var color := palette.colors[indexed_colors[index]]
			colors_rgb[index * 3 + 0] = color.r8
			colors_rgb[index * 3 + 1] = color.g8
			colors_rgb[index * 3 + 2] = color.b8
			if magic != "WAD2":
				continue

			colors_rgba[index * 4 + 0] = color.r8
			colors_rgba[index * 4 + 1] = color.g8
			colors_rgba[index * 4 + 2] = color.b8
			colors_rgba[index * 4 + 3] = 255
			if indexed_colors[index] == 255:
				colors_rgba[index * 4 + 3] = 0
				has_alpha = true
			elif indexed_colors[index] >= 224 and indexed_colors[index] < 255:
				fullbright_colors_rgb[index * 3 + 0] = color.r8
				fullbright_colors_rgb[index * 3 + 1] = color.g8
				fullbright_colors_rgb[index * 3 + 2] = color.b8
				has_fullbright_colors = true

		var image: Image
		if has_alpha:
			image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, colors_rgba)
		else:
			image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, colors_rgb)
		var image_texture := ImageTexture.create_from_image(image)

		var image2_texture: ImageTexture
		if has_fullbright_colors:
			var image2 := Image.create_from_data(width, height, false, Image.FORMAT_RGB8, fullbright_colors_rgb)
			image2_texture = ImageTexture.create_from_image(image2)
		var emission_suffix: String = MapperSettings.TEXTURE_SUFFIXES.get(BaseMaterial3D.TEXTURE_EMISSION, "_emission")
		var texture_name := name.to_lower()

		mutex.lock()
		wad.textures[texture_name] = image_texture
		if has_fullbright_colors:
			wad.textures[texture_name + emission_suffix] = image2_texture
		mutex.unlock()

	var extract_texture1 := func(thread_index: int) -> void:
		var thread_file := FileAccess.open(path, FileAccess.READ)
		if not thread_file:
			return
		extract_texture.call(thread_file, thread_index, texture1_positions[thread_index], default_palette)

	var extract_texture2 := func(thread_index: int) -> void:
		var thread_file := FileAccess.open(path, FileAccess.READ)
		if not thread_file:
			return
		thread_file.seek(texture2_positions[thread_index] + texture2_disk_sizes[thread_index] - 256 * 3 - 2)
		var texture2_palette := MapperPaletteResource.create_from_byte_array(thread_file.get_buffer(256 * 3))
		extract_texture.call(thread_file, thread_index, texture2_positions[thread_index], texture2_palette)

	# extracting textures
	if use_threads:
		var group_task1 := WorkerThreadPool.add_group_task(extract_texture1, texture1_positions.size(), -1, true)
		var group_task2 := WorkerThreadPool.add_group_task(extract_texture2, texture2_positions.size(), -1, true)

		WorkerThreadPool.wait_for_group_task_completion(group_task1)
		WorkerThreadPool.wait_for_group_task_completion(group_task2)
	else:
		for index in range(texture1_positions.size()):
			extract_texture.call(file, index, texture1_positions[index], default_palette)

		for index in range(texture2_positions.size()):
			file.seek(texture2_positions[index] + texture2_disk_sizes[index] - 256 * 3 - 2)
			var texture2_palette := MapperPaletteResource.create_from_byte_array(file.get_buffer(256 * 3))
			extract_texture.call(file, index, texture2_positions[index], texture2_palette)

	return wad
