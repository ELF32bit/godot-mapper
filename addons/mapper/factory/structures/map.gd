class_name MapperMap

var entities: Array[MapperEntity]
var wads: Array[MapperWadResource]

var materials: Dictionary
var classnames: Dictionary
var target_sources: Dictionary
var group_target_sources: Dictionary
var group_entities: Dictionary
var groups: Dictionary

var factory: MapperFactory
var settings: MapperSettings # shortcut to factory settings for build scripts
var loader: MapperLoader # shortcut to factory game loader for build scripts
var node: Node3D # shortcut to scene root for build scripts


func is_group_entity(entity: MapperEntity, group_type: StringName) -> bool:
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


func get_entity_group(entity: MapperEntity, group_type: StringName) -> MapperEntity:
	if not entity or not group_type in groups:
		return null
	var id: Variant = entity.get_int_property(group_type, null)
	if id == null or not id in groups[group_type]:
		return null
	return groups[group_type][id]


func get_entity_group_recursively(entity: MapperEntity, group_type: StringName, reverse: bool = false) -> Array[MapperEntity]:
	var entity_groups: Array[MapperEntity] = []
	var group := get_entity_group(entity, group_type)
	while group and entity_groups.size() < factory.settings.MAX_ENTITY_GROUP_DEPTH:
		if group in entity_groups or group == entity:
			entity_groups.append(group)
			break
		else:
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


func get_entity_group_entities(entity: MapperEntity, group_type: StringName, classname: String = "*") -> Array[MapperEntity]:
	var entity_group_entities: Array[MapperEntity] = []
	var entity_group := get_entity_group(entity, group_type)
	if not entity_group:
		return entity_group_entities
	bind_group_entities(entity_group, group_type)
	var classname_property := factory.settings.classname_property
	for group_entity in group_entities[entity_group]:
		# entities without classname, empty one, will not match here
		if group_entity.properties.get(classname_property, "").match(classname):
			entity_group_entities.append(group_entity)
	return entity_group_entities


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


func bind_group_target_source_property(group_entity: MapperEntity, group_type: StringName, property: StringName) -> void:
	if group_entity in group_target_sources:
		if property in group_target_sources[group_entity]:
			return
	bind_group_entities(group_entity, group_type)
	if not group_entity in group_entities:
		return
	if not group_entity in group_target_sources:
		group_target_sources[group_entity] = {}
	group_target_sources[group_entity][property] = {}
	for entity in group_entities[group_entity]:
		if not property in entity.properties:
			continue
		var entity_target_source: String = entity.properties[property]
		if not entity_target_source in group_target_sources[group_entity][property]:
			group_target_sources[group_entity][property][entity_target_source] = []
		group_target_sources[group_entity][property][entity_target_source].append(entity)


func get_entity_targets(entity: MapperEntity, destination_property: StringName, source_property: StringName, classname: String = "*", group_type: StringName = "") -> Array[MapperEntity]:
	var targets: Array[MapperEntity] = []
	if not destination_property in entity.properties:
		return targets
	if group_type.is_empty():
		bind_target_source_property(source_property)
		var classname_property := factory.settings.classname_property
		var entity_target_destination: String = entity.properties[destination_property]
		for map_entity in target_sources[source_property].get(entity_target_destination, []):
			# entities without classname, empty one, will not match here
			if map_entity.properties.get(classname_property, "").match(classname):
				targets.append(map_entity)
	else:
		var entity_group := get_entity_group(entity, group_type)
		bind_group_target_source_property(entity_group, group_type, source_property)
		var entity_target_destination: String = entity.properties[destination_property]
		for entity_group_entity in group_target_sources.get(entity_group, {}).get(source_property, {}).get(entity_target_destination, []):
			targets.append(entity_group_entity)
	return targets


func get_first_entity_target(entity: MapperEntity, destination_property: StringName, source_property: StringName, classname: String = "*", group_type: StringName = "") -> MapperEntity:
	var targets := get_entity_targets(entity, destination_property, source_property, classname, group_type)
	return targets[0] if targets.size() else null


func get_first_entity_target_recursively(entity: MapperEntity, destination_property: StringName, source_property: StringName, classname: String = "*", group_type: StringName = "") -> Array[MapperEntity]:
	var targets: Array[MapperEntity] = []
	var target := get_first_entity_target(entity, destination_property, source_property, classname, group_type)
	while target and targets.size() < factory.settings.MAX_ENTITY_TARGET_DEPTH:
		if target in targets or target == entity:
			targets.append(target)
			break
		else:
			targets.append(target)
		target = get_first_entity_target(target, destination_property, source_property, classname, group_type)
	return targets
