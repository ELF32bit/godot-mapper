class_name MapperMaterial

var base: BaseMaterial3D
var override: Material
var physics: PhysicsMaterial


func _init(base: BaseMaterial3D = null, override: Material = null, physics: PhysicsMaterial = null) -> void:
	self.base = base
	self.override = override
	self.physics = physics


func get_material() -> Material:
	return (override if override else base)


func get_metadata(property: StringName, default: Variant = null) -> Variant:
	if not override:
		return default
	return override.get_meta(property, default)


func get_metadata_list() -> PackedStringArray:
	if not override:
		return PackedStringArray()
	return override.get_meta_list()
