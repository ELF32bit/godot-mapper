class_name MapperEntityResource
extends Resource

@export var properties: Dictionary
@export var brushes: Array[MapperBrushResource]


func _init(properties: Dictionary = {}, brushes: Array[MapperBrushResource] = []) -> void:
	self.properties = properties
	self.brushes = brushes
