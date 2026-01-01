@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node := Node3D.new()

	# applying bound entity.node_properties (position, rotation)
	MapperUtilities.apply_entity_transform(entity, node, true)

	for brush in entity.brushes:
		var brush_node := MapperUtilities.create_brush(entity, brush, "RigidBody3D")
		if not brush_node:
			continue
		# parenting one global node to another with right local coordinates
		MapperUtilities.add_global_child(brush_node, node, map.settings)

	return node
