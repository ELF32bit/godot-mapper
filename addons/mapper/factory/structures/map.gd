class_name MapperMap

var name: String
var source_file: String
var entities: Array[MapperEntity]
var wads: Array[MapperWadResource]

var materials: Dictionary
var classnames: Dictionary
var target_sources: Dictionary
var _group_target_sources: Dictionary # hack: target sources limited to group
var group_entities: Dictionary
var groups: Dictionary

var metadata: Dictionary
var factory: MapperFactory
var settings: MapperSettings # shortcut to factory settings for build scripts
var loader: MapperLoader # shortcut to factory game loader for build scripts
var node: Node3D # shortcut to scene root for build scripts


func get_first_world_entity() -> MapperEntity:
	var world_entities: Array = classnames.get(settings.world_entity_classname, [])
	if world_entities.size():
		return world_entities[0]
	return null


func is_group_entity(entity: MapperEntity, group_type: StringName = "_tb_group") -> bool:
	if not entity:
		return false
	var id_property := factory.settings.group_entity_id_property
	var id: Variant = entity.get_int_property(id_property, null)
	if id != null:
		if group_type in groups:
			if id in groups[group_type]:
				if groups[group_type][id] == entity:
					return true
	return false


func get_entity_group(entity: MapperEntity, group_type: StringName = "_tb_group") -> MapperEntity:
	if not entity or not group_type in groups:
		return null
	var id: Variant = entity.get_int_property(group_type, null)
	if id == null or not id in groups[group_type]:
		return null
	return groups[group_type][id]


func get_entity_group_name(entity: MapperEntity, group_type: StringName = "_tb_group") -> String:
	var entity_group := get_entity_group(entity, group_type)
	if entity_group:
		return entity_group.properties.get(settings.group_entity_name_property, "")
	return ""


func get_entity_group_recursively(entity: MapperEntity, group_type: StringName = "_tb_group", reverse: bool = false) -> Array[MapperEntity]:
	var entity_groups: Array[MapperEntity] = []
	var entity_groups_set: Dictionary = { entity: true }
	var group := get_entity_group(entity, group_type)
	while group and entity_groups.size() < factory.settings.MAX_ENTITY_GROUP_DEPTH:
		if group in entity_groups_set:
			entity_groups.append(group)
			break
		else:
			entity_groups_set[group] = true
			entity_groups.append(group)
		group = get_entity_group(group, group_type)
	if reverse:
		entity_groups.reverse()
	return entity_groups


func bind_group_entities(group_entity: MapperEntity, group_type: StringName) -> void:
	if not is_group_entity(group_entity, group_type):
		return
	if group_entity in group_entities:
		return
	group_entities[group_entity] = []
	for entity in entities:
		var entity_groups := get_entity_group_recursively(entity, group_type)
		for entity_group_entity in entity_groups:
			if entity_group_entity == group_entity:
				group_entities[group_entity].append(entity)
				break


func get_entity_group_entities(entity: MapperEntity, group_type: StringName = "_tb_group", classname: String = "*") -> Array[MapperEntity]:
	var entity_group_entities: Array[MapperEntity] = []
	var entity_group := get_entity_group(entity, group_type)
	if not entity_group:
		return entity_group_entities
	bind_group_entities(entity_group, group_type)
	for group_entity in group_entities[entity_group]:
		# entities without classname, empty one, will not match here
		if group_entity.get_classname_property("").match(classname):
			entity_group_entities.append(group_entity)
	return entity_group_entities


func get_entity_layer(entity: MapperEntity) -> MapperEntity:
	if not settings.group_entity_enabled:
		return null
	if is_group_entity(entity, "_tb_layer"):
		return entity
	var entity_layer := get_entity_group(entity, "_tb_layer")
	if entity_layer:
		return entity_layer
	var entity_groups := get_entity_group_recursively(entity, "_tb_group", true)
	if entity_groups.size() > 0:
		var entity_group_layer := get_entity_group(entity_groups[0], "_tb_layer")
		if entity_group_layer:
			return entity_group_layer
	return null


func get_entity_layer_name(entity: MapperEntity) -> String:
	var entity_layer := get_entity_layer(entity)
	if entity_layer:
		return entity_layer.properties.get(settings.group_entity_name_property, "")
	return ""


func get_entity_layer_visibility(entity: MapperEntity) -> bool:
	var entity_layer := get_entity_layer(entity)
	if entity_layer:
		if entity_layer.get_int_property(settings.tb_layer_visibility_property, 0) != 0:
			return false
	return true


func get_entity_layer_locking(entity: MapperEntity) -> bool:
	var entity_layer := get_entity_layer(entity)
	if entity_layer:
		if entity_layer.get_int_property(settings.tb_layer_locking_property, 0) != 0:
			return true
	return false


func bind_target_source_property(property: StringName) -> void:
	if property in target_sources:
		return
	var target_sources_of_property: Dictionary = {}
	for entity in entities:
		if not property in entity.properties:
			continue
		var entity_target_source: String = entity.properties[property]
		if not entity_target_source in target_sources_of_property:
			target_sources_of_property[entity_target_source] = []
		target_sources_of_property[entity_target_source].append(entity)
	target_sources[property] = target_sources_of_property


func _bind_group_target_source_property(group_entity: MapperEntity, group_type: StringName, property: StringName) -> void:
	if group_entity in _group_target_sources:
		if property in _group_target_sources[group_entity]:
			return
	bind_group_entities(group_entity, group_type)
	if not group_entity in group_entities:
		return
	if not group_entity in _group_target_sources:
		_group_target_sources[group_entity] = {}
	_group_target_sources[group_entity][property] = {}
	for entity in group_entities[group_entity]:
		if not property in entity.properties:
			continue
		var entity_target_source: String = entity.properties[property]
		if not entity_target_source in _group_target_sources[group_entity][property]:
			_group_target_sources[group_entity][property][entity_target_source] = []
		_group_target_sources[group_entity][property][entity_target_source].append(entity)


func get_entity_targets(entity: MapperEntity, destination_property: StringName, source_property: StringName, classname: String = "*", _group_type: StringName = "") -> Array[MapperEntity]:
	var targets: Array[MapperEntity] = []
	if not destination_property in entity.properties:
		return targets
	if _group_type.is_empty():
		bind_target_source_property(source_property)
		var entity_target_destination: String = entity.properties[destination_property]
		for map_entity in target_sources[source_property].get(entity_target_destination, []):
			# entities without classname, empty one, will not match here
			if map_entity.get_classname_property("").match(classname):
				targets.append(map_entity)
	else: # will limit target sources to the first group, this can be useful for duplicating spotlights
		var entity_group := get_entity_group(entity, _group_type)
		_bind_group_target_source_property(entity_group, _group_type, source_property)
		var entity_target_destination: String = entity.properties[destination_property]
		for entity_group_entity in _group_target_sources.get(entity_group, {}).get(source_property, {}).get(entity_target_destination, []):
			targets.append(entity_group_entity)
	return targets


func get_first_entity_target(entity: MapperEntity, destination_property: StringName, source_property: StringName, classname: String = "*", _group_type: StringName = "") -> MapperEntity:
	var targets := get_entity_targets(entity, destination_property, source_property, classname, _group_type)
	if targets.size():
		return targets[0]
	return null


func get_first_entity_target_recursively(entity: MapperEntity, destination_property: StringName, source_property: StringName, classname: String = "*", _group_type: StringName = "") -> Array[MapperEntity]:
	var targets: Array[MapperEntity] = []
	var targets_set: Dictionary = { entity: true }
	var target := get_first_entity_target(entity, destination_property, source_property, classname, _group_type)
	while target and targets.size() < factory.settings.MAX_ENTITY_TARGET_DEPTH:
		if target in targets_set:
			targets.append(target)
			break
		else:
			targets_set[target] = true
			targets.append(target)
		target = get_first_entity_target(target, destination_property, source_property, classname, _group_type)
	return targets
