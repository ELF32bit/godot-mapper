class_name MapperSettings
extends Resource

const DEFAULT_GAME_LOADER: GDScript = preload("loaders/default.gd")
const QUAKE_GAME_LOADER: GDScript = preload("loaders/quake.gd")

const DEFAULT_GAME_PROPERTY_CONVERTER: GDScript = preload("properties/default.gd")

const SHADER_TEXTURE_SLOTS := {
	BaseMaterial3D.TEXTURE_ALBEDO: "albedo_texture",
	BaseMaterial3D.TEXTURE_METALLIC: "metallic_texture",
	BaseMaterial3D.TEXTURE_ROUGHNESS: "roughness_texture",
	BaseMaterial3D.TEXTURE_EMISSION: "emission_texture",
	BaseMaterial3D.TEXTURE_NORMAL: "normal_texture",
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
	BaseMaterial3D.TEXTURE_ORM: "orm_texture"
}

const TEXTURE_SUFFIXES := {
	BaseMaterial3D.TEXTURE_ALBEDO: "_albedo",
	BaseMaterial3D.TEXTURE_METALLIC: "_metallic",
	BaseMaterial3D.TEXTURE_ROUGHNESS: "_roughness",
	BaseMaterial3D.TEXTURE_EMISSION: "_emission",
	BaseMaterial3D.TEXTURE_NORMAL: "_normal",
	BaseMaterial3D.TEXTURE_RIM: "_rim",
	BaseMaterial3D.TEXTURE_CLEARCOAT: "_clearcoat",
	BaseMaterial3D.TEXTURE_FLOWMAP: "_anisotropy",
	BaseMaterial3D.TEXTURE_AMBIENT_OCCLUSION: "_ao",
	BaseMaterial3D.TEXTURE_HEIGHTMAP: "_heightmap",
	BaseMaterial3D.TEXTURE_SUBSURFACE_SCATTERING: "_subsurf_scatter",
	BaseMaterial3D.TEXTURE_SUBSURFACE_TRANSMITTANCE: "_subsurf_scatter_transmittance",
	BaseMaterial3D.TEXTURE_BACKLIGHT: "_backlight",
	BaseMaterial3D.TEXTURE_REFRACTION: "_refraction",
	BaseMaterial3D.TEXTURE_DETAIL_MASK: "_detail_mask",
	BaseMaterial3D.TEXTURE_DETAIL_ALBEDO: "_albedo_detail",
	BaseMaterial3D.TEXTURE_DETAIL_NORMAL: "_normal_detail",
	BaseMaterial3D.TEXTURE_ORM: "_orm"
}

const MAX_ENTITY_GROUP_DEPTH: int = 128
const MAX_ENTITY_TARGET_DEPTH: int = 1024
const MAX_ENTITY_PARENT_DEPTH: int = 1024
const MAX_MATERIAL_TEXTURES: int = 1024

var options: Dictionary

@export var use_threads := false
@export var force_deterministic := true

@export var basis := Basis(Vector3(0.0, 0.0, -1.0), Vector3(-1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0)):
	set(value):
		basis = value.orthonormalized()

@export var unit_size: float = 32.0
@export var epsilon: float = 1e-03
@export var grid_snap_enabled := true
@export var grid_snap_step: float = 0.125

@export var readable_node_names := true
@export var lightmap_unwrap := true
@export var lightmap_texel_size: float = 0.5
@export var occlusion_culling := true
@export var shadow_meshes := true # BUG: does not work with forward+ rendering
@export var store_barycentric_coordinates := true # instead of vertex colors
@export var use_advanced_barycentric_coordinates := true # with alpha values
@export var prefer_static_lighting := true # preference for build scripts
@export var max_distribution_density: float = 4.0 # per axis

@export var store_base_materials := true
@export var base_materials_texture_filter := BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
@export var skip_material: String = "skip"
@export var skip_material_aliases: PackedStringArray = []
@export var skip_material_affects_collision := true

@export var world_entity_classname: String = "worldspawn"
@export var world_entity_wad_property_enabled := true
@export var world_entity_wad_property: StringName = "wad"
@export var world_entity_extra_brush_entities_enabled := true
@export var world_entity_extra_brush_entities_classnames: PackedStringArray = ["func_group"]

@export var group_entity_enabled := true
@export var group_entity_classname: String = "func_group"
@export var group_entity_type_property: StringName = "_tb_type"
@export var group_entity_types: PackedStringArray = ["_tb_group", "_tb_layer"]
@export var group_entity_id_property: StringName = "_tb_id"

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
}

@export var aabb_metadata_property_enabled := false
@export var aabb_metadata_property: StringName = "aabb"
@export var planes_metadata_property_enabled := false
@export var planes_metadata_property: StringName = "planes"

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
			game_maps_directory = value.trim_suffix("/")
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
			game_wads_directory = value.trim_suffix("/")
		else:
			push_error("Invalid game mdls directory, must be relative path.")

@export var game_material_extensions: PackedStringArray = ["tres", "material", "res"]
@export var game_texture_extensions: PackedStringArray = ["png", "tga", "jpg", "jpeg"]
@export var game_sound_extensions: PackedStringArray = ["ogg", "wav", "mp3"]
@export var game_script_extensions: PackedStringArray = ["gd"]

@export var post_build_script_enabled := true
@export var post_build_script_name: StringName = "__post"
@export var post_build_faces_colors_enabled := true
@export var post_build_faces_colors_method: StringName = "__build_faces_colors"

@export var warn_about_degenerate_brushes := true

@export var game_property_converter: GDScript = DEFAULT_GAME_PROPERTY_CONVERTER
@export var game_loader: GDScript = DEFAULT_GAME_LOADER
@export var random_number_generator_seed: int = 0


func _init(options: Dictionary = {}) -> void:
	for option in options.keys():
		if option is String or option is StringName:
			self.set(option, options[option])
	self.options = options.duplicate()
