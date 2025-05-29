@tool
extends EditorImportPlugin

enum { PRESET_DEFAULT }


func _get_importer_name() -> String:
	return "mapper.map.scene"


func _get_visible_name() -> String:
	return "MapperScene"


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["map"])


func _get_save_extension() -> String:
	return "scn"


func _get_resource_type() -> String:
	return "PackedScene"


func _get_preset_count() -> int:
	return 1


func _get_preset_name(preset_index: int) -> String:
	match preset_index:
		PRESET_DEFAULT:
			return "Default"
		_:
			return "Unknown"


func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	match preset_index:
		PRESET_DEFAULT:
			return [
				{
					"name": "game",
					"default_value": 0,
					"property_hint": PROPERTY_HINT_ENUM,
					"hint_string": "Generic,Quake,Custom",
				},
				{
					"name": "wads",
					"default_value": [],
					"property_hint": PROPERTY_HINT_TYPE_STRING,
					"hint_string": "%s/%s:*.wad" % [TYPE_STRING, PROPERTY_HINT_FILE],
				},
				{
					"name": "options",
					"default_value": {},
				},
			]
		_:
			return []


func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true


func _get_import_order() -> int:
	return EditorImportPlugin.IMPORT_ORDER_SCENE + 100


func _get_priority() -> float:
	return 1.0


func _can_import_threaded() -> bool:
	return false


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var map := MapperMapResource.load_from_file(source_file)
	if not map:
		return ERR_PARSE_ERROR

	var map_options := {}
	match options.get("game", 0):
		0:
			map_options["game_directory"] = "res://mapping/generic"
			map_options["alternative_game_directories"] = ["res://mapping/quake"]
			map_options["game_loader"] = MapperSettings.DEFAULT_GAME_LOADER
		1:
			map_options["game_directory"] = "res://mapping/quake"
			map_options["game_loader"] = MapperSettings.QUAKE_GAME_LOADER
			map_options["skip_material_affects_collision"] = false
			map_options["prefer_static_lighting"] = true
		_:
			pass
	map_options.merge(options.get("options", {}), true)

	var settings := MapperSettings.new(map_options)
	var factory := MapperFactory.new(settings)
	# loading wads from options
	var wads: Array[MapperWadResource] = []
	for wad_path in options.get("wads", []):
		if wad_path != null:
			if ResourceLoader.exists(wad_path, "MapperWadResource"):
				var wad: MapperWadResource = null
				wad = ResourceLoader.load(wad_path, "MapperWadResource")
				if wad:
					wads.append(wad)
	var scene := factory.build_map(map, wads)

	var save_flags: int = ResourceSaver.FLAG_COMPRESS
	if options.get("options", {}).get("bundle_resources", false):
		save_flags = save_flags | ResourceSaver.FLAG_BUNDLE_RESOURCES
	return ResourceSaver.save(scene, "%s.%s" % [save_path, _get_save_extension()], save_flags)
