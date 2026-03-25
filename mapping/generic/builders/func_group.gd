@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	# func_group is either _tb_group or _tb_layer
	if not map.is_group_entity(entity, "_tb_group"):
		return null

	# finding group entities one level deep (can be other groups)
	map.bind_group_entities(entity, "_tb_group")

	# parenting group entities to the group node
	for group_entity in map.group_entities.get(entity, []):
		group_entity.parent = entity

	# calculating group AABB from brushes
	var aabb := AABB()
	var aabb_is_empty := true
	for group_entity in map.group_entities.get(entity, []):
		if not group_entity.aabb.has_surface(): continue
		if aabb_is_empty:
			aabb = group_entity.aabb
			aabb_is_empty = false
		else: aabb = aabb.merge(group_entity.aabb)
	for brush in entity.brushes:
		if not brush.aabb.has_surface(): continue
		if aabb_is_empty:
			aabb = brush.aabb
			aabb_is_empty = false
		else: aabb = aabb.merge(brush.aabb)

	# calculating group AABB from point entities if there are no brushes
	if aabb_is_empty:
		for group_entity in map.group_entities.get(entity, []):
			if not group_entity.brushes.size() == 0: continue
			var origin = group_entity.get_origin_property(null)
			if origin == null: continue
			if aabb_is_empty:
				aabb = AABB(origin, Vector3.ZERO)
				aabb_is_empty = false
			else: aabb = aabb.expand(origin)

	# binding group properties
	entity.node_properties["position"] = aabb.get_center()
	entity.bind_string_property(map.settings.group_entity_name_property, "name")

	return Node3D.new()
