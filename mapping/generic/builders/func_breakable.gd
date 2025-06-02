@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node := Node3D.new()
	MapperUtilities.apply_entity_transform(entity, node)

	for brush in entity.brushes:
		var brush_node := MapperUtilities.create_brush(entity, brush, "RigidBody3D")
		MapperUtilities.add_global_child(brush_node, node, map.settings)

	return node
