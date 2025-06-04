class_name MapperLoader

var settings: MapperSettings
var custom_wads: Array[MapperWadResource]
var random_number_generator := RandomNumberGenerator.new()

var animated_texture_cache: Dictionary
var wad_cache: Dictionary
var map_cache: Dictionary
var mdl_cache: Dictionary


func validate_material_name(material: String) -> String:
	var filename := material.get_file()
	var directory := material.trim_suffix(filename)
	var reg_ex := RegEx.new()
	reg_ex.compile("-[0-9]+$")
	filename = reg_ex.sub(filename, "").strip_edges()
	reg_ex.compile("\\+[0-9]+$")
	filename = reg_ex.sub(filename, "").strip_edges()
	return directory + filename


func load_resource(resource: String, type_hint: String = "") -> Resource:
	for extension in settings.game_resource_extensions:
		var file := resource + "." + extension
		var path := settings.game_directory.path_join(file)
		if ResourceLoader.exists(path, type_hint):
			return load(path)
		for alternative_game_directory in settings.alternative_game_directories:
			var alternative_path := alternative_game_directory.path_join(file)
			if ResourceLoader.exists(alternative_path, type_hint):
				return load(alternative_path)
	return null


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

	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0

	return material


func load_texture(texture: String, wads: Array[MapperWadResource] = []) -> Texture2D:
	var wad_texture := texture.to_lower().get_file()
	for wad in wads:
		if wad_texture in wad.textures:
			return wad.textures[wad_texture]
	for extension in settings.game_texture_extensions:
		var file := texture + "." + extension
		var path := settings.game_directory.path_join(file)
		if ResourceLoader.exists(path, "Texture2D"):
			return load(path)
		for alternative_game_directory in settings.alternative_game_directories:
			var alternative_path := alternative_game_directory.path_join(file)
			if ResourceLoader.exists(alternative_path, "Texture2D"):
				return load(alternative_path)
	return null


func load_animated_texture(texture: String, wads: Array[MapperWadResource] = []) -> Texture2D:
	var reg_ex := RegEx.new()

	# trying to get animation frame from texture name
	reg_ex.compile("-[0-9]+(_[A-Za-z]*$|$)")
	var frame_pattern := reg_ex.search(texture)
	if frame_pattern:
		var suffix := frame_pattern.get_string()
		reg_ex.compile("-[0-9]+")
		var texture_frame := reg_ex.search(suffix).get_string().trim_prefix("-")
		reg_ex.compile("_[A-Za-z]*$|$")
		var other_suffix := reg_ex.search(suffix).get_string()
		var texture_name := texture.trim_suffix(suffix)

		var frames: Array[Texture2D] = []
		while not frames.size() > AnimatedTexture.MAX_FRAMES:
			var current_frame := str(frames.size()).pad_zeros(texture_frame.length())
			var path := texture_name + "-" + current_frame + other_suffix
			var texture_resource := load_texture(path, wads)
			if not texture_resource:
				if frames.size() and current_frame < texture_frame:
					push_warning("Texture %s has wrong frame format." % [texture])
					frames.clear()
				break
			frames.append(texture_resource)

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
			animated_texture.one_shot = false
			for frame in range(animated_texture.frames):
				animated_texture.set_frame_texture(frame, frames[frame])
				animated_texture.set_frame_duration(frame, settings.animated_textures_frame_duration)

			var reference_texture := load_resource(texture_name, "AnimatedTexture")
			if reference_texture and reference_texture is AnimatedTexture:
				animated_texture.pause = reference_texture.pause
				animated_texture.one_shot = reference_texture.one_shot
				animated_texture.speed_scale = reference_texture.speed_scale
				if animated_texture.frames == reference_texture.frames:
					for frame in range(reference_texture.frames):
						var duration: float = reference_texture.get_frame_duration(frame)
						animated_texture.set_frame_duration(frame, duration)

			return animated_texture

	return load_texture(texture, wads)


func load_animated_textures(texture: String, wads: Array[MapperWadResource] = []) -> Dictionary:
	var textures: Array[Texture2D] = []

	var reg_ex := RegEx.new()
	reg_ex.compile("\\+[0-9]+(-[0-9]+)?(_[A-Za-z]*$|$)")
	var number_pattern := reg_ex.search(texture)
	if number_pattern:
		var suffix := number_pattern.get_string()

		reg_ex.compile("\\+[0-9]+")
		var texture_number := reg_ex.search(suffix).get_string().trim_prefix("+")
		var texture_frame := ""
		reg_ex.compile("-[0-9]+")
		var frame_pattern := reg_ex.search(suffix)
		if frame_pattern != null:
			texture_frame = "-" + "0".pad_zeros(frame_pattern.get_string().length() - 1)
		reg_ex.compile("_[A-Za-z]*$|$")
		var other_suffix := texture_frame + reg_ex.search(suffix).get_string()
		var texture_name := texture.trim_suffix(suffix)

		while not textures.size() > settings.MAX_MATERIAL_TEXTURES:
			var current_number := str(textures.size()).pad_zeros(texture_number.length())
			var path := texture_name + "+" + current_number + other_suffix
			var texture_resource := load_animated_texture(path, wads)
			if not texture_resource:
				if textures.size() and current_number < texture_number:
					push_warning("Texture %s has wrong number format." % [texture])
				if current_number <= texture_number:
					textures.clear()
				break
			else:
				textures.append(texture_resource)
		if textures.size():
			return {"textures": textures, "texture_index": texture_number.to_int()}

	var texture_resource := load_animated_texture(texture, wads)
	if texture_resource:
		textures.append(texture_resource)

	return {"textures": textures, "texture_index": -1}


func load_script(script: String) -> GDScript:
	for matching_path in generate_matching_paths(script):
		for extension in settings.game_script_extensions:
			var file := matching_path + "." + extension
			var path := settings.game_directory.path_join(file)
			if ResourceLoader.exists(path, "GDScript"):
				return load(path)
			for alternative_game_directory in settings.alternative_game_directories:
				var alternative_path := alternative_game_directory.path_join(file)
				if ResourceLoader.exists(alternative_path, "GDScript"):
					return load(alternative_path)
	return null


func load_sound(sound: String) -> AudioStream:
	for extension in settings.game_sound_extensions:
		var file := sound + "." + extension
		var path := settings.game_directory.path_join(file)
		if ResourceLoader.exists(path, "AudioStream"):
			return load(path)
		for alternative_game_directory in settings.alternative_game_directories:
			var alternative_path := alternative_game_directory.path_join(file)
			if ResourceLoader.exists(alternative_path, "AudioStream"):
				return load(alternative_path)
	return null


func load_wad(wad: String) -> MapperWadResource:
	if wad.get_extension().is_empty():
		wad = wad.trim_suffix(".") + ".wad"
	var path := settings.game_directory.path_join(wad)
	if ResourceLoader.exists(path, "MapperWadResource"):
		return load(path)
	for alternative_game_directory in settings.alternative_game_directories:
		var alternative_path := alternative_game_directory.path_join(wad)
		if ResourceLoader.exists(alternative_path, "MapperWadResource"):
			return load(alternative_path)
	return null


func load_wad_raw(wad: String, palette: MapperPaletteResource = null) -> MapperWadResource:
	if wad.get_extension().is_empty():
		wad = wad.trim_suffix(".") + ".wad"
	var path := settings.game_directory.path_join(wad)
	if wad_cache.has([path, palette]):
		return wad_cache[[path, palette]]

	var wad_resource := MapperWadResource.load_from_file(path, palette, settings.use_threads)
	if not wad_resource:
		for alternative_game_directory in settings.alternative_game_directories:
			var alternative_path := alternative_game_directory.path_join(wad)
			wad_resource = MapperWadResource.load_from_file(alternative_path, palette, settings.use_threads)
			if wad_resource:
				break
	if not wad_resource:
		return null

	wad_cache[[path, palette]] = wad_resource
	return wad_resource


func load_map(map: String) -> PackedScene:
	if map.get_extension().is_empty():
		map = map.trim_suffix(".") + ".map"
	var path := settings.game_directory.path_join(map)
	# not checking for any cyclic references within maps at all
	if ResourceLoader.exists(path, "PackedScene"):
		return load(path)
	for alternative_game_directory in settings.alternative_game_directories:
		var alternative_path := alternative_game_directory.path_join(map)
		if ResourceLoader.exists(alternative_path, "PackedScene"):
			return load(alternative_path)
	return null


func load_map_raw(map: String, use_cache: bool = true) -> PackedScene:
	if map.get_extension().is_empty():
		map = map.trim_suffix(".") + ".map"
	var path := settings.game_directory.path_join(map)
	# not checking for any cyclic references within maps at all
	if use_cache and map_cache.has(path):
		return map_cache[path]

	var map_resource := MapperMapResource.load_from_file(path)
	if not map_resource:
		for alternative_game_directory in settings.alternative_game_directories:
			var alternative_path := alternative_game_directory.path_join(map)
			map_resource = MapperMapResource.load_from_file(alternative_path)
			if map_resource:
				break
	if not map_resource:
		return null

	var settings_copy := MapperSettings.new(settings.options)
	# changing seed on copied settings to make navigation groups unique to map
	# instances of cached maps will have unusable overlapping navigation regions
	settings_copy.random_number_generator_seed = random_number_generator.randi()
	var factory := MapperFactory.new(settings_copy)
	var scene := factory.build_map(map_resource, custom_wads)
	if use_cache:
		map_cache[path] = scene

	return scene


func load_mdl(mdl: String) -> PackedScene:
	if mdl.get_extension().is_empty():
		mdl = mdl.trim_suffix(".") + ".mdl"
	var path := settings.game_directory.path_join(mdl)
	if ResourceLoader.exists(path, "PackedScene"):
		return load(path)
	for alternative_game_directory in settings.alternative_game_directories:
		var alternative_path := alternative_game_directory.path_join(mdl)
		if ResourceLoader.exists(alternative_path, "PackedScene"):
			return load(alternative_path)
	return null


func load_mdl_raw(mdl: String, palette: MapperPaletteResource = null) -> PackedScene:
	if mdl.get_extension().is_empty():
		mdl = mdl.trim_suffix(".") + ".mdl"
	var path := settings.game_directory.path_join(mdl)
	if mdl_cache.has([path, palette]):
		return mdl_cache[[path, palette]]

	var mdl_resource := MapperMdlResource.load_from_file(path, palette)
	if not mdl_resource:
		for alternative_game_directory in settings.alternative_game_directories:
			var alternative_path := alternative_game_directory.path_join(mdl)
			mdl_resource = MapperMdlResource.load_from_file(alternative_path, palette)
			if mdl_resource:
				break
	if not mdl_resource:
		return null

	var settings_copy := MapperSettings.new(settings.options)
	var factory := MapperFactory.new(settings_copy)
	var scene := factory.build_mdl(mdl_resource)
	mdl_cache[[path, palette]] = scene

	return scene


func generate_matching_paths(path: String) -> PackedStringArray:
	var filename := path.get_file()
	var directory := path.trim_suffix(filename)
	var paths := PackedStringArray()

	var right := func(string: String, characters: String) -> String:
		var index := clampi(string.rfind(characters), 0, string.length())
		return string.right(string.length() - index)

	if not path.is_empty():
		paths.append(path)
	while not filename.is_empty():
		var suffix: String = right.call(filename, "_")
		filename = filename.rstrip("0123456789")
		filename = filename.trim_suffix(suffix).rstrip("_")
		if filename.is_empty():
			paths.append(path + "_")
		paths.append(directory + filename + "_")
	return paths
