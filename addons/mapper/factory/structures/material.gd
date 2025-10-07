class_name MapperMaterial

var base: BaseMaterial3D
var override: Material


func _init(base: BaseMaterial3D = null, override: Material = null) -> void:
	self.base = base
	self.override = override


func get_material() -> Material:
	return (override if override else base)


func get_metadata() -> Dictionary:
	var metadata: Dictionary = {}
	if not override:
		return metadata
	for property in override.get_meta_list():
		metadata[property] = override.get_meta(property, null)
	return metadata
