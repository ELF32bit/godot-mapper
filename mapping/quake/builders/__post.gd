@warning_ignore("unused_parameter")
static func build(map: MapperMap) -> void:
	var lightmap_gi := MapperUtilities.create_lightmap_gi(map, map.node)
	lightmap_gi.set_script(preload("../scripts/editor/lightmap.gd"))

	if "worldspawn" in map.classnames:
		preload("worldspawn.gd").post_build_environment(map)
