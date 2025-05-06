class_name MapperMaterial
extends Resource

@export var base: BaseMaterial3D
@export var override: Material


func _init(base: BaseMaterial3D = null, override: Material = null):
	self.base = base
	self.override = override


func get_material() -> Material:
	return (override if override else base)
