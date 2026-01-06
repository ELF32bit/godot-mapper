@warning_ignore("unused_parameter")
static func build(map: MapperMap) -> void:
	return

@warning_ignore("unused_parameter")
static func build_faces_colors(face: MapperFace, colors: PackedColorArray) -> void:
	# face can be a triangle, quad and n-gon with a central starting vertex
	# furthermore, n-gons have one more duplicate vertex at the end of the loop
	if not face.parameters.size():
		return
	var source_colors := colors.duplicate()

	# barycentric wireframes mode can be adjusted via special face flags
	# colors.a = (8.0 - flags) / 8.0, where flags are [1], [2], [4]
	# [1] will disable red vertex, [2] - green, [4] - blue
	for index in range(colors.size()):
		colors[index].a = (8.0 - float(face.parameters[0])) / 8.0

	# face colors array can be resized to triangulate the face
	colors.clear()
	for index in range(1, source_colors.size() - 1):
		colors.append(source_colors[0])
		colors.append(source_colors[index])
		colors.append(source_colors[index + 1])

	# barycentric wireframes mode can be applied per triangle in the face
	for index in range(mini(face.parameters.size(), source_colors.size() - 2)):
		var flags := (8.0 - float(face.parameters[index])) / 8.0
		colors[index * 3 + 0].a = flags
		colors[index * 3 + 1].a = flags
		colors[index * 3 + 2].a = flags

	# other face parameters, like UV flow vectors, can be applied here too
	pass
