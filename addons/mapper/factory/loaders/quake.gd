extends MapperLoader


func validate_material_name(material: String) -> String:
	var filename := material.get_file()
	var directory := material.trim_suffix(filename)

	if filename.length() > 2 and filename[0] == "+":
		if filename[1].to_lower() in "0123456789abcdefghij":
			return directory + filename.trim_prefix(filename[0] + filename[1])

	if filename.length() > 1 and filename[0] in "*{":
		return directory + filename.trim_prefix(filename[0])

	return material


func load_material(material: String) -> Material:
	material = validate_material_name(material)
	if material.is_empty():
		return null

	for matching_path in generate_matching_paths(material):
		for extension in settings.game_material_extensions:
			var file := matching_path + "." + extension
			var path := settings.game_directory.path_join(file)
			if ResourceLoader.exists(path, "Material"):
				return load(path)
			for alternative_game_directory in settings.alternative_game_directories:
				var alternative_path := alternative_game_directory.path_join(file)
				if ResourceLoader.exists(alternative_path, "Material"):
					return load(alternative_path)
	return null


func load_base_material() -> BaseMaterial3D:
	var material := StandardMaterial3D.new()
	material.texture_filter = settings.base_materials_texture_filter

	material.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0

	return material


func load_animated_texture(texture: String, wads: Array[MapperWadResource] = []) -> Texture2D:
	var filename := texture.get_file()
	var directory := texture.trim_suffix(filename)

	if filename.length() > 2 and filename[0] == "+":
		var frames: Array[Texture2D] = []

		var sequence: String
		if filename[1] in "0123456789":
			sequence = "0123456789"
		elif filename[1] in "abcdefghij":
			sequence = "abcdefghij"

		for character in sequence:
			var path := filename
			path[1] = character
			path = directory + path
			var frame := load_texture(path, wads)
			if not frame:
				if frames.size() and character < filename[1]:
					push_warning("Texture %s has wrong frame format." % [texture])
					frames.clear()
				break
			frames.append(frame)

		if frames.size():
			var animated_texture: AnimatedTexture = null
			if settings.store_unique_animated_textures:
				animated_texture = AnimatedTexture.new()
			else:
				if frames in animated_texture_cache:
					return animated_texture_cache[frames]
				animated_texture_cache[frames] = AnimatedTexture.new()
				animated_texture = animated_texture_cache[frames]

			animated_texture.frames = frames.size()
			for frame in range(animated_texture.frames):
				animated_texture.set_frame_texture(frame, frames[frame])
				animated_texture.set_frame_duration(frame, 1.0 / 5.0)
			return animated_texture

	return load_texture(texture, wads)


func load_animated_textures(texture: String, wads: Array[MapperWadResource] = []) -> Dictionary:
	var textures: Array[Texture2D] = []
	var texture_index: int = -1

	var texture1 := load_animated_texture(texture, wads)
	if not texture1:
		return {"textures": textures, "texture_index": texture_index}
	textures.append(texture1)

	var filename := texture.get_file()
	var directory := texture.trim_suffix(filename)

	if filename.length() > 2 and filename[0] == "+":
		if filename[1] in "0123456789":
			var a_filename := filename
			a_filename[1] = "a"
			texture_index = 0

			var texture2 := load_animated_texture(directory + a_filename, wads)
			if texture2:
				textures.append(texture2)

	return {"textures": textures, "texture_index": texture_index}
