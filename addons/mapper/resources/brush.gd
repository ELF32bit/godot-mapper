class_name MapperBrushResource
extends Resource

@export var faces: Array[MapperFaceResource]


func _init(faces: Array[MapperFaceResource] = []) -> void:
	self.faces = faces
