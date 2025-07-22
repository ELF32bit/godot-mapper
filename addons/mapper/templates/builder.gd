@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node := MapperUtilities.create_brush_entity(entity, "Node3D")
	return node if node else Marker3D.new()
