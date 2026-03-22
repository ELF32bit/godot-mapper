@tool
extends EditorImportPlugin

enum { PRESET_DEFAULT }

const DEFAULT_GAMES: Dictionary = {
	"Generic": {
		"game_directory": "res://mapping/generic",
		"alternative_game_directories": ["res://mapping/quake"],
		"game_loader": MapperSettings.DEFAULT_GAME_LOADER,
	},
	"Quake": {
		"game_directory": "res://mapping/quake",
		"game_loader": MapperSettings.QUAKE_GAME_LOADER,
		"skip_material_affects_collision": false,
		"prefer_static_lighting": true,
	}
}


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
	var games := _load_configuration_file()
	match preset_index:
		PRESET_DEFAULT:
			return [
				{
					"name": "game",
					"default_value": 0,
					"property_hint": PROPERTY_HINT_ENUM,
					"hint_string": ",".join(games.keys()),
				},
				{
					"name": "wads",
					"default_value": [],
					"property_hint": PROPERTY_HINT_TYPE_STRING,
					"hint_string": "%s/%s:*.wad" % [TYPE_STRING, PROPERTY_HINT_FILE],
				},
				{
					"name": "options",
					"default_value": {
						"print_progress": false,
					},
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

	var map_options: Dictionary = {}
	var games := _load_configuration_file().duplicate(true)
	map_options = games.get(games.keys()[options.get("game", 0)], {})
	map_options.merge(options.get("options", {}), true)

	# loading wads from options
	var wads: Array[MapperWadResource] = []
	for wad_path in options.get("wads", []):
		if wad_path != null:
			if ResourceLoader.exists(wad_path, "MapperWadResource"):
				var wad: MapperWadResource = null
				wad = ResourceLoader.load(wad_path, "MapperWadResource")
				if wad:
					wads.append(wad)

	var settings := MapperSettings.new(map_options)
	var factory := MapperFactory.new(settings)
	var scene := factory.build_map(map, wads)

	var save_flags: int = ResourceSaver.FLAG_COMPRESS
	if options.get("options", {}).get("bundle_resources", false):
		save_flags = save_flags | ResourceSaver.FLAG_BUNDLE_RESOURCES
	return ResourceSaver.save(scene, "%s.%s" % [save_path, _get_save_extension()], save_flags)


static func _load_configuration_file() -> Dictionary:
	if not ResourceLoader.exists("res://addons/mapper.gd", "GDScript"):
		return DEFAULT_GAMES
	var configuration_file: Variant = load("res://addons/mapper.gd")
	if not configuration_file is GDScript:
		return DEFAULT_GAMES
	var configuration: Dictionary = configuration_file.get_script_constant_map()
	if not configuration.get("MAPPER_GAMES", null) is Dictionary:
		return DEFAULT_GAMES
	var games: Dictionary = configuration.get("MAPPER_GAMES", {})
	for game_name in games:
		if not typeof(game_name) in [TYPE_STRING, TYPE_STRING_NAME]:
			return DEFAULT_GAMES
		if not games[game_name] is Dictionary:
			return DEFAULT_GAMES
	return games
