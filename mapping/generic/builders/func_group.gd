@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	if not map.is_group_entity(entity, "_tb_group"):
		return null

	# finding group entities
	map.bind_group_entities(entity, "_tb_group")
	var group_center := Vector3.ZERO
	var count: int = 0

	# parenting group entities to the group node
	for group_entity in map.group_entities.get(entity, []):
		group_entity.parent = entity

	# calculating group center
	for group_entity in map.group_entities.get(entity, []):
		if group_entity.brushes.size():
			group_center += group_entity.center
			count += 1
	for brush in entity.brushes:
		group_center += brush.center
		count += 1

	if count:
		group_center /= count
	entity.node_properties["position"] = group_center
	entity.bind_string_property(map.settings.group_entity_name_property, "name")

	return Node3D.new()
