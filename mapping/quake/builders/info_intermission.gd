@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node := Camera3D.new()
	node.add_to_group("info_intermission", true)
	return node
