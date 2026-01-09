@warning_ignore("unused_parameter")
static func build(map: MapperMap) -> void:
	return

@warning_ignore("unused_parameter")
static func build_faces_colors(face: MapperFace, colors: PackedColorArray) -> void:
	# face can be a triangle, quad and n-gon with a central starting vertex
	# additionally, n-gons have one more duplicate vertex at the end of the loop
	if not face.parameters.size() > 2:
		return
	var source_colors := colors.duplicate()
	var face_value := face.parameters[2]

	# barycentric wireframes mode can be adjusted via special face flags
	# colors.a = (16.0 - flags) / 16.0, where flags are [1], [2], [4], [8]
	# [8] is the sign of face value distinguishing triangles from n-gons
	# [1] will disable red vertex, [2] - green, [4] - blue
	var ngon_flag: int = (8 if int(face_value) < 0 else 0)
	face_value = str(absi(int(face_value)))

	# face colors array can be resized to triangulate the face
	colors.clear()
	for index in range(1, source_colors.size() - 1):
		colors.append(source_colors[0])
		colors.append(source_colors[index])
		colors.append(source_colors[index + 1])

	# barycentric wireframes mode can be applied per triangle in the face
	for index in range(mini(face_value.length(), source_colors.size() - 2)):
		var vertex_flags := int(face_value[index]) % 8
		var flags := (16.0 - float(vertex_flags | ngon_flag)) / 16.0
		colors[index * 3 + 0].a = flags
		colors[index * 3 + 1].a = flags
		colors[index * 3 + 2].a = flags

	# other face parameters, like UV flow vectors, can be applied here too
	pass
