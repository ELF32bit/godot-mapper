@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	return MapperUtilities.create_merged_brush_entity(entity, "Area3D", false, true, false)
