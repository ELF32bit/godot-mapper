class_name MapperMapResource
extends Resource

const MAX_FACES_PER_BRUSH: int = 128

@export var name: String
@export var source_file: String
@export var entities: Array[MapperEntityResource]


func _init(name: String = "", source_file: String = "", entities: Array[MapperEntityResource] = []) -> void:
	self.name = name
	self.source_file = source_file
	self.entities = entities


static func load_from_file(path: String) -> MapperMapResource:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return null

	var faces: Array[MapperFaceResource]
	var entities: Array[MapperEntityResource]
	var is_inside_entity := false
	var is_inside_brush := false
	var line_number: int = 0

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		line_number += 1

		# ignoring empty lines and comments
		if line.is_empty() or line.begins_with("//"):
			continue

		if line.begins_with("{"):
			if is_inside_entity:
				if is_inside_brush:
					# cant be inside entity while inside brush
					return null
				else:
					faces = []
					is_inside_brush = true
			else:
				entities.append(MapperEntityResource.new())
				is_inside_entity = true
		elif line.begins_with("}"):
			if is_inside_brush:
				if faces.size() > MAX_FACES_PER_BRUSH:
					push_warning("Line %s: Brush has more than %s faces, not importing." % [line_number, MAX_FACES_PER_BRUSH])
				elif not faces.size():
					push_warning("Line %s: Brush has no faces, not importing." % [line_number])
				else:
					entities[-1].brushes.append(MapperBrushResource.new(faces))

				is_inside_brush = false
			else:
				if not is_inside_entity:
					# cant be inside brush and not be inside entity
					return null
				else:
					is_inside_entity = false
		elif is_inside_brush:
			var face := MapperFaceResource.create_from_string(line)

			if face:
				faces.append(face)
			else:
				push_warning("Line %s: Brush face has wrong format, not importing." % [line_number])
		elif is_inside_entity:
			var line_split := line.split('"', false)
			var property := StringName(line_split[0])

			if line_split.size() >= 3:
				entities[-1].properties[property] = line_split[2]
			elif line_split.size() == 2:
				entities[-1].properties[property] = line_split[1]

	return MapperMapResource.new(path.get_file().get_basename(), path, entities)
