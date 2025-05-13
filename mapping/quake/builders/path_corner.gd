@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node := Marker3D.new()
	node.set_script(preload("../scripts/path_corner.gd"))

	entity.bind_string_property("targetname", "name")
	entity.bind_node_path_array_property("target", "targetname", "targets")
	entity.bind_float_property("wait", "wait_time")

	return node
