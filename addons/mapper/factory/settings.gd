class_name MapperSettings
extends Resource

const DEFAULT_GAME_LOADER: GDScript = preload("loaders/default.gd")
const QUAKE_GAME_LOADER: GDScript = preload("loaders/quake.gd")

const DEFAULT_GAME_PROPERTY_CONVERTER: GDScript = preload("properties/default.gd")

const MAX_ENTITY_GROUP_DEPTH: int = 256
const MAX_ENTITY_TARGET_DEPTH: int = 4096
const MAX_ENTITY_PARENT_DEPTH: int = 256
const MAX_MATERIAL_TEXTURES: int = 1024
const MAX_MAP_LOADING_DEPTH: int = 8

## Shader texture parameters recognized by the plugin.
const SHADER_TEXTURE_SLOTS := {
	BaseMaterial3D.TEXTURE_ALBEDO: "albedo_texture",
	BaseMaterial3D.TEXTURE_METALLIC: "metallic_texture",
	BaseMaterial3D.TEXTURE_ROUGHNESS: "roughness_texture",
	BaseMaterial3D.TEXTURE_EMISSION: "emission_texture",
	BaseMaterial3D.TEXTURE_NORMAL: "normal_texture",
	#BaseMaterial3D.TEXTURE_BENT_NORMAL: "bent_normal_texture",
	BaseMaterial3D.TEXTURE_RIM: "rim_texture",
	BaseMaterial3D.TEXTURE_CLEARCOAT: "clearcoat_texture",
	BaseMaterial3D.TEXTURE_FLOWMAP: "anisotropy_flowmap",
	BaseMaterial3D.TEXTURE_AMBIENT_OCCLUSION: "ao_texture",
	BaseMaterial3D.TEXTURE_HEIGHTMAP: "heightmap_texture",
	BaseMaterial3D.TEXTURE_SUBSURFACE_SCATTERING: "subsurf_scatter_texture",
	BaseMaterial3D.TEXTURE_SUBSURFACE_TRANSMITTANCE: "subsurf_scatter_transmittance_texture",
	BaseMaterial3D.TEXTURE_BACKLIGHT: "backlight_texture",
	BaseMaterial3D.TEXTURE_REFRACTION: "refraction_texture",
	BaseMaterial3D.TEXTURE_DETAIL_MASK: "detail_mask",
	BaseMaterial3D.TEXTURE_DETAIL_ALBEDO: "detail_albedo",
	BaseMaterial3D.TEXTURE_DETAIL_NORMAL: "detail_normal",
	BaseMaterial3D.TEXTURE_ORM: "orm_texture",
}

## PBR texture suffixes recognized by the plugin. Currently one word only.
const TEXTURE_SUFFIXES := {
	BaseMaterial3D.TEXTURE_ALBEDO: "_albedo",
	BaseMaterial3D.TEXTURE_METALLIC: "_metallic",
	BaseMaterial3D.TEXTURE_ROUGHNESS: "_roughness",
	BaseMaterial3D.TEXTURE_EMISSION: "_emission",
	BaseMaterial3D.TEXTURE_NORMAL: "_normal",
	#BaseMaterial3D.TEXTURE_BENT_NORMAL: "_bnormal",
	BaseMaterial3D.TEXTURE_RIM: "_rim",
	BaseMaterial3D.TEXTURE_CLEARCOAT: "_clearcoat",
	BaseMaterial3D.TEXTURE_FLOWMAP: "_anisotropy",
	BaseMaterial3D.TEXTURE_AMBIENT_OCCLUSION: "_ao",
	BaseMaterial3D.TEXTURE_HEIGHTMAP: "_heightmap",
	BaseMaterial3D.TEXTURE_SUBSURFACE_SCATTERING: "_subsurface",
	BaseMaterial3D.TEXTURE_SUBSURFACE_TRANSMITTANCE: "_transmittance",
	BaseMaterial3D.TEXTURE_BACKLIGHT: "_backlight",
	BaseMaterial3D.TEXTURE_REFRACTION: "_refraction",
	BaseMaterial3D.TEXTURE_DETAIL_MASK: "_dmask",
	BaseMaterial3D.TEXTURE_DETAIL_ALBEDO: "_dalbedo",
	BaseMaterial3D.TEXTURE_DETAIL_NORMAL: "_dnormal",
	BaseMaterial3D.TEXTURE_ORM: "_orm",
}

## Stores settings overrides and custom options.
var options: Dictionary

## Can provide 25-50% increase in speed.
## If enabled, make sure that the map import plugin is single threaded.
@export var use_threads := false
## If disabled, can slightly increase the speed of distribution generation.
## The resulting scene file will have a different hash after every reimport.
@export var force_deterministic := true

## Map coordinate system. Can also be used to rotate the entire map.
@export var basis := Basis(
	Vector3(0.0, 0.0, -1.0),
	Vector3(-1.0, 0.0, 0.0),
	Vector3(0.0, 1.0, 0.0))

## Size of Godot unit in map units.
@export var unit_size: float = 32.0
## Comparison epsilon in map units. Make sure to divide it by unit size.
@export var epsilon: float = 0.001
## Grid snap can dramatically improve numerical precision and representation.
@export var grid_snap_enabled := true
## Grid snap step in map units. Make sure to divide it by unit size.
@export var grid_snap_step: float = 0.125

## If false, will not unwrap geometry for lightmaps.
## Make sure to compile Godot editor with `XA_MULTITHREADED 0` or disable.
@export var lightmap_unwrap := true
## Controls the size of each texel on the baked lightmap.
@export var lightmap_texel_size: float = 0.5
## Preference for build scripts. Use it to control GI mode of dynamic entities.
@export var prefer_static_lighting := true

## If false, can slightly increase the speed of scene generation.
@export var readable_node_names := true
## If false, occluder instances will not be generated.
@export var occlusion_culling := true
## If false, entity shadow meshes will not be generated.
## Currently does not work with Forward+ rendering, recommended to disable.
@export var shadow_meshes := true # BUG: does not work with Forward+ rendering

## If false, will not store barycentric coordinates as vertex colors.
@export var store_barycentric_coordinates := true
## If false, will store basic barycentric coordinates without alpha modes.
@export var use_advanced_barycentric_coordinates := true

## Max surface (^2) and volume (^3) distribution density per axis.
@export var max_distribution_density: float = 4.0
## Global distribution density multiplier for optimization.
@export var distribution_density_scale: float = 1.0
@export var mass_scale: float = 10.0

## If false, will free up surface material override slots on mesh instances.
@export var store_base_materials := true
@export var base_materials_texture_filter := BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
## If true, will reference simple override materials, instead of copying.
@export var reference_override_materials := false
@export var store_unique_animated_textures := false
@export var animated_textures_frame_duration: float = 0.2
@export var shader_texture_slots := SHADER_TEXTURE_SLOTS
@export var texture_suffixes := TEXTURE_SUFFIXES

@export var classname_property: StringName = "classname"
@export var origin_property: StringName = "origin"
@export var angle_property: StringName = "angle"
@export var angles_property: StringName = "angles"
@export var mangle_property: StringName = "mangle"

@export var smooth_shading_property_enabled := true
@export var smooth_shading_property: StringName = "_phong"
@export var smooth_shading_split_angle_property: StringName = "_phong_angle"

@export var cast_shadow_property_enabled := true
@export var cast_shadow_property: StringName = "_shadow"

@export var lightmap_scale_property_enabled := true
@export var lightmap_scale_property: StringName = "_lmscale"

@export var skip_material_enabled := true
@export var skip_material_name: String = "skip"
@export var skip_material_aliases: PackedStringArray = []
@export var skip_material_affects_collision := true

@export var skip_entities_enabled := true
@export var skip_entities_classnames: PackedStringArray = []
@export var skip_entities_without_classname := false

@export var world_entity_classname: String = "worldspawn"
@export var world_entity_wads_property_enabled := true
@export var world_entity_wads_property: StringName = "wad"
@export var world_entity_wads_palette: MapperPaletteResource = null
@export var world_entity_extra_brush_entities_enabled := true
@export var world_entity_extra_brush_entities_classnames: PackedStringArray = ["func_group"]

@export var group_entity_enabled := true
@export var group_entity_classname: String = "func_group"
@export var group_entity_type_property: StringName = "_tb_type"
@export var group_entity_types: PackedStringArray = ["_tb_group", "_tb_layer"]
@export var group_entity_name_property: StringName = "_tb_name"
@export var group_entity_id_property: StringName = "_tb_id"

@export var tb_layer_omit_from_export_enabled := true
@export var tb_layer_omit_from_export_property: StringName = "_tb_layer_omit_from_export"
@export var tb_layer_visibility_property: StringName = "_tb_layer_hidden"
@export var tb_layer_locking_property: StringName = "_tb_layer_locked"
@export var tb_layer_index_property: StringName = "_tb_layer_sort_index"

@export var alternative_textures_metadata_property: StringName = "alternative_textures"
@export var override_material_metadata_properties := {
	"mesh_disabled": "mesh_disabled",
	"cast_shadow": "cast_shadow",
	"gi_mode": "gi_mode",
	"ignore_occlusion": "ignore_occlusion",
	"collision_disabled": "collision_disabled",
	"collision_layer": "collision_layer",
	"collision_mask": "collision_mask",
	"occluder_disabled": "occluder_disabled",
	"occluder_mask": "occluder_mask",
	"mass_density": "mass_density",
}

@export var game_directory: String = "":
	set(value):
		if not value.is_empty() and value.is_absolute_path():
			game_directory = value.trim_suffix("/")
		else:
			push_error("Invalid game directory, must be absolute path.")

@export var alternative_game_directories: PackedStringArray = []:
	set(value):
		alternative_game_directories.clear()
		for directory in value:
			if not directory.is_empty() and directory.is_absolute_path():
				alternative_game_directories.append(directory.trim_suffix("/"))
			else:
				push_error("Invalid alternative game directory, must be absolute path.")
				continue

@export var game_builders_directory: String = "builders":
	set(value):
		if not value.is_empty() and value.is_relative_path():
			game_builders_directory = value.trim_suffix("/")
		else:
			push_error("Invalid game builders directory, must be relative path.")

@export var game_materials_directory: String = "materials":
	set(value):
		if not value.is_empty() and value.is_relative_path():
			game_materials_directory = value.trim_suffix("/")
		else:
			push_error("Invalid game materials directory, must be relative path.")

@export var game_textures_directory: String = "textures":
	set(value):
		if not value.is_empty() and value.is_relative_path():
			game_textures_directory = value.trim_suffix("/")
		else:
			push_error("Invalid game textures directory, must be relative path.")

@export var game_sounds_directory: String = "sounds":
	set(value):
		if not value.is_empty() and value.is_relative_path():
			game_sounds_directory = value.trim_suffix("/")
		else:
			push_error("Invalid game sounds directory, must be relative path.")

@export var game_maps_directory: String = "maps":
	set(value):
		if not value.is_empty() and value.is_relative_path():
			game_maps_directory = value.trim_suffix("/")
		else:
			push_error("Invalid game maps directory, must be relative path.")

@export var game_map_data_directory: String = "mapdata":
	set(value):
		if not value.is_empty() and value.is_relative_path():
			game_map_data_directory = value.trim_suffix("/")
		else:
			push_error("Invalid game map data directory, must be relative path.")

@export var game_wads_directory: String = "wads":
	set(value):
		if not value.is_empty() and value.is_relative_path():
			game_wads_directory = value.trim_suffix("/")
		else:
			push_error("Invalid game wads directory, must be relative path.")

@export var game_mdls_directory: String = "mdls":
	set(value):
		if not value.is_empty() and value.is_relative_path():
			game_mdls_directory = value.trim_suffix("/")
		else:
			push_error("Invalid game mdls directory, must be relative path.")

@export var game_resource_extensions: PackedStringArray = ["tres", "res"]
@export var game_scene_extensions: PackedStringArray = ["tscn", "scn", "res"]
@export var game_shader_extensions: PackedStringArray = ["gdshader", "res", "tres"]
@export var game_material_extensions: PackedStringArray = ["tres", "material", "res"]
@export var game_texture_extensions: PackedStringArray = ["png", "tga", "jpg", "jpeg"]
@export var game_sound_extensions: PackedStringArray = ["ogg", "wav", "mp3"]
@export var game_script_extensions: PackedStringArray = ["gd"]

@export var post_build_script_enabled := true
@export var post_build_script_name: StringName = "__post"
@export var post_build_faces_colors_enabled := true
@export var post_build_faces_colors_method: StringName = "build_faces_colors"

@export var print_progress := false
@export var print_progress_verbose := true
@export var warn_about_degenerate_brushes := true
@export var use_experimental_brush_algorithm := false

@export var mdls_frame_duration: float = 0.1
@export var mdls_palette: MapperPaletteResource = null
@export var mdls_skins_metadata_property: StringName = "skins"
@export var mdls_skin: int = 0

@export var game_property_converter: GDScript = DEFAULT_GAME_PROPERTY_CONVERTER
@export var game_loader: GDScript = DEFAULT_GAME_LOADER
@export var map_data_seed: int = 0


func _init(options: Dictionary = {}) -> void:
	for option in options.keys():
		if option is String or option is StringName:
			self.set(option, options[option])
	self.options = options.duplicate()


func is_skip_entity_classname(classname: String) -> bool:
	if not skip_entities_enabled:
		return false
	var skip_entity := false
	for skip_classname in skip_entities_classnames:
		if not skip_classname.begins_with("^"):
			if classname.match(skip_classname):
				skip_entity = true
				break
	if skip_entity:
		for skip_classname in skip_entities_classnames:
			if skip_classname.begins_with("^"):
				if classname.match(skip_classname.trim_prefix("^")):
					skip_entity = false
					break
	return skip_entity


func get_up_vector() -> Vector3:
	return basis.z.normalized()


func get_up_axis_index() -> int:
	return get_up_vector().abs().max_axis_index()


func get_up_axis() -> Vector3:
	var up_axis := Vector3.ZERO
	var up_vector := get_up_vector()
	var up_axis_index := get_up_axis_index()
	up_axis[up_axis_index] = signf(up_vector[up_axis_index])
	return up_axis


func get_forward_vector() -> Vector3:
	return basis.x.normalized()


func get_forward_axis_index() -> int:
	return get_forward_vector().abs().max_axis_index()


func get_forward_axis() -> Vector3:
	var forward_axis := Vector3.ZERO
	var forward_vector := get_forward_vector()
	var forward_axis_index := get_forward_axis_index()
	forward_axis[forward_axis_index] = signf(forward_vector[forward_axis_index])
	return forward_axis


func get_forward_rotation() -> Quaternion:
	var forward := get_forward_vector()
	if forward.is_equal_approx(-Vector3.FORWARD):
		return Quaternion(get_up_vector(), PI)
	return Quaternion(Vector3.FORWARD, forward)


func get_right_vector() -> Vector3:
	return -basis.y.normalized()


func get_right_axis_index() -> int:
	return get_right_vector().abs().max_axis_index()


func get_right_axis() -> Vector3:
	var right_axis := Vector3.ZERO
	var right_vector := get_right_vector()
	var right_axis_index := get_right_axis_index()
	right_axis[right_axis_index] = signf(right_vector[right_axis_index])
	return right_axis
