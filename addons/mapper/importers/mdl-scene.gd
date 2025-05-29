@tool
extends EditorImportPlugin

enum { PRESET_DEFAULT }


func _get_importer_name() -> String:
	return "mapper.mdl.scene"


func _get_visible_name() -> String:
	return "MapperScene"


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["mdl"])


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
					"name": "palette",
					"default_value": "",
					"property_hint": PROPERTY_HINT_FILE,
					"hint_string": "*.lmp",
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
	return EditorImportPlugin.IMPORT_ORDER_SCENE + 50


func _get_priority() -> float:
	return 1.0


func _can_import_threaded() -> bool:
	return false


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var palette_path: String = options.get("palette", "").strip_edges()
	var palette: MapperPaletteResource = null
	if ResourceLoader.exists(palette_path):
		palette = load(palette_path) as MapperPaletteResource

	var mdl := MapperMdlResource.load_from_file(source_file, palette)
	if not mdl:
		return ERR_PARSE_ERROR

	var mdl_options := {}
	mdl_options.merge(options.get("options", {}), true)
	var settings := MapperSettings.new(mdl_options)
	var factory := MapperFactory.new(settings)
	var scene := factory.build_mdl(mdl)

	var save_flags: int = ResourceSaver.FLAG_COMPRESS
	return ResourceSaver.save(scene, "%s.%s" % [save_path, _get_save_extension()], save_flags)
