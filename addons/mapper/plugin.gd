@tool
extends EditorPlugin

var palette_import_plugin: Variant = null
var wad_import_plugin: Variant = null
var map_import_plugin: Variant = null
var map_scene_import_plugin: Variant = null
var mdl_import_plugin: Variant = null
var mdl_scene_import_plugin: Variant = null


func _enter_tree() -> void:
	palette_import_plugin = preload("importers/palette.gd").new()
	wad_import_plugin = preload("importers/wad.gd").new()
	mdl_import_plugin = preload("importers/mdl.gd").new()
	map_import_plugin = preload("importers/map.gd").new()
	map_scene_import_plugin = preload("importers/map-scene.gd").new()
	mdl_scene_import_plugin = preload("importers/mdl-scene.gd").new()

	add_import_plugin(palette_import_plugin)
	add_import_plugin(wad_import_plugin)
	add_import_plugin(mdl_import_plugin)
	add_import_plugin(map_import_plugin)
	add_import_plugin(map_scene_import_plugin)
	add_import_plugin(mdl_scene_import_plugin)


func _exit_tree() -> void:
	remove_import_plugin(palette_import_plugin)
	remove_import_plugin(wad_import_plugin)
	remove_import_plugin(mdl_import_plugin)
	remove_import_plugin(map_import_plugin)
	remove_import_plugin(map_scene_import_plugin)
	remove_import_plugin(mdl_scene_import_plugin)

	palette_import_plugin = null
	wad_import_plugin = null
	mdl_import_plugin = null
	map_import_plugin = null
	map_scene_import_plugin = null
	mdl_scene_import_plugin = null
