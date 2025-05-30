class_name MapperFactory

var settings: MapperSettings
var game_property_converter: MapperPropertyConverter
var game_loader: MapperLoader

var random_number_generator := RandomNumberGenerator.new()
var build_time: int = 0
var progress: float = 0.0


func _init(settings: MapperSettings) -> void:
	self.settings = settings
	# creating game loader instance
	var game_loader_instance := settings.game_loader.new()
	if game_loader_instance is MapperLoader:
		game_loader = game_loader_instance
		game_loader.settings = settings
	else:
		push_error("Game loader script must extend MapperLoader.")
		self.settings = null
	# creating game property converter instance
	var game_property_converter_instance := settings.game_property_converter.new()
	if game_property_converter_instance is MapperPropertyConverter:
		game_property_converter = game_property_converter_instance
		game_property_converter.game_loader = game_loader_instance
		game_property_converter.settings = settings
	else:
		push_error("Game property converter script must extend MapperPropertyConverter.")
		self.settings = null


func build_map(map: MapperMapResource, wads: Array[MapperWadResource] = [], print_progress: bool = false) -> PackedScene:
	var factory := func(action: Callable, progress: float, comment: String) -> void:
		var time := Time.get_ticks_msec()
		action.call()
		time = Time.get_ticks_msec() - time
		build_time += time
		self.progress = progress / 21.0 # number of build steps
		if print_progress:
			print("(%.2f) %s: %.3fs" % [self.progress, comment, time / 1000.0])

	var parallel_task := func(action: Callable, elements: int, use_threads: bool = true) -> void:
		if use_threads and settings.use_threads:
			var group_task := WorkerThreadPool.add_group_task(action, elements, -1, true)
			WorkerThreadPool.wait_for_group_task_completion(group_task)
		else:
			for index in range(elements):
				action.call(index)

	game_loader.source_file = map.source_file
	game_loader.custom_wads.assign(wads)
	random_number_generator.state = 0
	progress = 0.0
	build_time = 0

	if not settings:
		push_error("Error building map %s, factory settings are missing." % [map.name])
		return null
	random_number_generator.seed = settings.random_number_generator_seed

	# creating scene root and map structures from resources
	var packed_scene := PackedScene.new()
	var scene_root := Node3D.new()
	scene_root.name = map.name

	var map_structure := MapperMap.new()
	map_structure.wads.append_array(wads)
	map_structure.factory = self
	map_structure.settings = settings
	map_structure.loader = game_loader
	map_structure.node = scene_root

	var face_structures: Array[MapperFace] = []
	var brush_structures: Array[MapperBrush] = []
	var entity_structures: Array[MapperEntity] = map_structure.entities
	var smooth_entities: Array[MapperEntity] = []

	var post_build_script: GDScript = null
	if settings.post_build_script_enabled:
		var path := settings.game_builders_directory.path_join(settings.post_build_script_name)
		post_build_script = game_loader.load_script(path)

	var generate_structures := func() -> void:
		var world_entity_extra_brushes: Array[MapperBrush] = []
		var forward_rotation := Quaternion(Vector3.FORWARD, settings.basis.x)
		var forward_rotation_euler := forward_rotation.get_euler()

		# preparing to create map structure groups dictionary
		if settings.group_entity_enabled:
			for group_entity_type in settings.group_entity_types:
				map_structure.groups[group_entity_type] = {}

		for entity in map.entities:
			var entity_structure := MapperEntity.new()
			entity_structure.properties = entity.properties.duplicate()
			entity_structure.factory = self
			if settings.smooth_shading_property_enabled:
				if entity_structure.is_smooth_shaded():
					smooth_entities.append(entity_structure)
			entity_structures.append(entity_structure)

			var is_world_entity_extra_brush_entity := false
			if settings.classname_property in entity_structure.properties:
				# creating map structure classnames dictionary
				var entity_classname: String = entity_structure.get_classname_property(null)
				if not entity_classname in map_structure.classnames:
					map_structure.classnames[entity_classname] = []
				map_structure.classnames[entity_classname].append(entity_structure)

				# also adding brushes from world entity extra brush entity to first world entity if enabled
				if settings.world_entity_extra_brush_entities_enabled:
					if entity_classname in settings.world_entity_extra_brush_entities_classnames:
						is_world_entity_extra_brush_entity = true

				# creating map structure groups dictionary
				if settings.group_entity_enabled:
					if entity_classname == settings.group_entity_classname:
						if settings.group_entity_type_property in entity_structure.properties:
							var group_entity_type: String = entity_structure.properties[settings.group_entity_type_property]
							var type_index := settings.group_entity_types.find(group_entity_type)
							var id: Variant = entity_structure.get_int_property(settings.group_entity_id_property, null)
							if type_index != -1 and id != null:
								map_structure.groups[settings.group_entity_types[type_index]][id] = entity_structure

			# binding common entity properties
			entity_structure.bind_origin_property("position")
			entity_structure.node_properties[StringName("rotation")] = forward_rotation_euler
			entity_structure.bind_angle_property("rotation")
			entity_structure.bind_angles_property("rotation")
			entity_structure.bind_mangle_property("rotation")

			for brush in entity.brushes:
				var brush_structure := MapperBrush.new()
				entity_structure.brushes.append(brush_structure)
				brush_structures.append(brush_structure)
				if is_world_entity_extra_brush_entity:
					world_entity_extra_brushes.append(brush_structure)
				brush_structure.factory = self

				for face in brush.faces:
					var face_structure := MapperFace.new()
					brush_structure.faces.append(face_structure)
					face_structures.append(face_structure)

					face_structure.point1 = face.point1
					face_structure.point2 = face.point2
					face_structure.point3 = face.point3
					face_structure.material_name = face.material
					face_structure.u_axis = face.u_axis
					face_structure.v_axis = face.v_axis
					face_structure.uv_shift = face.uv_shift
					face_structure.uv_valve = face.uv_valve
					face_structure.rotation = deg_to_rad(face.rotation)
					face_structure.scale = face.scale
					face_structure.parameters = face.parameters.duplicate()
					face_structure.factory = self

		# adding extra world entity brushes to first world entity entity without modifying source entities
		if settings.world_entity_extra_brush_entities_enabled:
			var world_entity: MapperEntity = map_structure.classnames.get(settings.world_entity_classname, [null])[0]
			if world_entity:
				world_entity.brushes.append_array(world_entity_extra_brushes)

	var generate_faces := func(thread_index: int) -> void:
		var face := face_structures[thread_index]

		face.point1 = settings.basis * face.point1
		face.point2 = settings.basis * face.point2
		face.point3 = settings.basis * face.point3
		face.plane = Plane(face.point1, face.point2, face.point3)

		if face.uv_valve:
			face.u_axis = settings.basis * face.u_axis
			face.v_axis = settings.basis * face.v_axis

		# removing texture suffixes from material names
		for suffix in settings.texture_suffixes.values():
			if face.material_name.ends_with(suffix):
				face.material_name = face.material_name.trim_suffix(suffix)
				break

		if settings.skip_material_enabled:
			var material_file := face.material_name.get_file()
			if material_file.matchn(settings.skip_material):
				face.skip = true
			else:
				for skip_material_alias in settings.skip_material_aliases:
					if material_file.matchn(skip_material_alias):
						face.skip = true
						break

	var generate_materials := func() -> void:
		for face in face_structures:
			if not face.material_name in map_structure.materials:
				map_structure.materials[face.material_name] = MapperMaterial.new()
			face.material = map_structure.materials[face.material_name]

	var generate_brushes := func(thread_index: int) -> void:
		var brush := brush_structures[thread_index]

		# finding face vertices forming convex hull by intersecting face planes
		for face1 in brush.faces:
			for face2 in brush.faces:
				for face3 in brush.faces:
					var vertex: Variant = face1.plane.intersect_3(face2.plane, face3.plane)
					if vertex != null:
						if brush.has_point(vertex) and not face1.has_vertex(vertex):
							face1.vertices.append(vertex)

		# removing brush faces that failed to form triangles
		for index in range(brush.faces.size() - 1, -1, -1):
			if brush.faces[index].vertices.size() < 3:
				brush.faces.remove_at(index)
				brush.is_degenerate = true

		# snapping brush vertices to grid to improve precision
		if settings.grid_snap_enabled:
			var grid_snap_step := settings.grid_snap_step
			for face in brush.faces:
				var face_vertices := face.vertices
				for index in range(face_vertices.size()):
					face_vertices[index].x = snappedf(face_vertices[index].x, grid_snap_step)
					face_vertices[index].y = snappedf(face_vertices[index].y, grid_snap_step)
					face_vertices[index].z = snappedf(face_vertices[index].z, grid_snap_step)

		# creating brush vertex normals from plane normals
		for face in brush.faces:
			var face_normals := face.normals
			face_normals.resize(face.vertices.size())
			face_normals.fill(face.plane.normal)

		# finding brush surfaces and materials
		for face in brush.faces:
			if not face.material_name in brush.surfaces:
				brush.surfaces[face.material_name] = []
			brush.surfaces[face.material_name].append(face)
			brush.materials[face.material_name] = face.material

		# calculating face centers and brush center
		brush.center = Vector3.ZERO
		if brush.faces.size():
			for face in brush.faces:
				face.center = Vector3.ZERO
				for vertex in face.vertices:
					face.center += vertex
				face.center /= face.vertices.size()
				brush.center += face.center
			brush.center /= brush.faces.size()

		# winding brush faces and setting up face data
		var sort_function := func(a: Vector4, b: Vector4) -> bool:
			return a.w > b.w

		for face in brush.faces:
			var wound_vertices: Array[Vector4] = []
			wound_vertices.resize(face.vertices.size())
			for index in range(face.vertices.size()):
				var d := face.vertices[index] - face.center
				var u := (face.vertices[1] - face.vertices[0]).normalized()
				var v := u.cross(face.plane.normal).normalized()
				var uv := Vector2(-d.dot(u), d.dot(v))
				wound_vertices[index] = Vector4(d.x, d.y, d.z, uv.angle())
			wound_vertices.sort_custom(sort_function)
			for index in range(face.vertices.size()):
				var d := wound_vertices[index]
				face.vertices[index] = Vector3(d.x, d.y, d.z) + face.center

		# scaling brush coordinates
		var scale := (1.0 / settings.unit_size)
		var transform := Transform3D.IDENTITY.scaled(Vector3.ONE * scale)
		for face in brush.faces:
			face.plane.d *= scale
			face.center *= scale
			face.vertices = transform * face.vertices
			face.uv_shift *= scale
		brush.center *= scale

	var generate_smooth_entity_normals := func(thread_index: int) -> void:
		var entity := smooth_entities[thread_index]

		var split_angle_property := settings.smooth_shading_split_angle_property
		var split_angle: float = entity.get_float_property(split_angle_property, 89.0)
		split_angle = deg_to_rad(clampf(split_angle, 0.0, 180.0))
		var epsilon := settings.epsilon

		# collecting entity faces
		var entity_faces: Array[MapperFace] = []
		for brush in entity.brushes:
			for face in brush.faces:
				if face.skip:
					continue
				entity_faces.append(face)

		# discarding faces in the same plane with same centers
		var unique_entity_faces: Array[bool] = []
		unique_entity_faces.resize(entity_faces.size())
		unique_entity_faces.fill(true)

		for index1 in range(entity_faces.size()):
			if not unique_entity_faces[index1]:
				continue

			var face1 := entity_faces[index1]
			var face_center1 := face1.center
			var plane_center1 := face1.plane.get_center()
			var face1_vertices_size := face1.vertices.size()
			var face1_vertices := face1.vertices

			for index2 in range(index1 + 1, entity_faces.size()):
				if not unique_entity_faces[index2]:
					continue

				var face2 := entity_faces[index2]
				var face2_vertices_size := face2.vertices.size()
				if face1_vertices_size != face2_vertices_size:
					continue

				var face_center2 := face2.center
				if not absf(face_center1.x - face_center2.x) < epsilon:
					continue
				if not absf(face_center1.y - face_center2.y) < epsilon:
					continue
				if not absf(face_center1.z - face_center2.z) < epsilon:
					continue

				var plane_center2 := face2.plane.get_center()
				if not absf(plane_center1.x - plane_center2.x) < epsilon:
					continue
				if not absf(plane_center1.y - plane_center2.y) < epsilon:
					continue
				if not absf(plane_center1.z - plane_center2.z) < epsilon:
					continue

				var is_different_face := false
				var face2_vertices := face2.vertices
				for vertex1 in face1_vertices:
					var is_different_vertex := true
					for vertex2 in face2_vertices:
						if not absf(vertex1.x - vertex2.x) < epsilon:
							continue
						if not absf(vertex1.y - vertex2.y) < epsilon:
							continue
						if not absf(vertex1.z - vertex2.z) < epsilon:
							continue
						is_different_vertex = false
					if is_different_vertex:
						is_different_face = true
						break
				if is_different_face:
					continue

				unique_entity_faces[index1] = false
				unique_entity_faces[index2] = false

		# collecting unique vertices and face normals
		var vertices := PackedVector3Array()
		var indices: Array[PackedInt64Array] = []
		var faces: Array[Array] = []

		for entity_face_index in range(entity_faces.size()):
			if not unique_entity_faces[entity_face_index]:
				continue
			var face := entity_faces[entity_face_index]
			var face_vertices := face.vertices

			for index1 in range(face_vertices.size()):
				var vertex := face_vertices[index1]
				var is_unique_vertex := true

				for index2 in range(vertices.size()):
					var unique_vertex := vertices[index2]

					if not absf(vertex.x - unique_vertex.x) < epsilon:
						continue
					if not absf(vertex.y - unique_vertex.y) < epsilon:
						continue
					if not absf(vertex.z - unique_vertex.z) < epsilon:
						continue

					indices[index2].append(index1)
					faces[index2].append(face)
					is_unique_vertex = false
					break

				if is_unique_vertex:
					vertices.append(vertex)
					indices.append(PackedInt64Array([index1]))
					faces.append([face])

		# calculating smooth normals
		for index1 in range(faces.size()):
			var normals := PackedVector3Array()
			var faces1: Array = faces[index1]
			normals.resize(faces1.size())

			for index2 in range(faces1.size()):
				normals[index2] = faces1[index2].plane.normal

			for index2 in range(faces1.size()):
				var faces12: MapperFace = faces1[index2]
				var faces12_normal: Vector3 = faces12.plane.normal
				for index3 in range(index2 + 1, faces1.size()):
					var faces13: MapperFace = faces1[index3]
					var faces13_normal: Vector3 = faces13.plane.normal
					if faces12_normal.angle_to(faces13_normal) < split_angle:
						normals[index2] += faces13_normal
						normals[index3] += faces12_normal
				var face12_smooth_normal := normals[index2].normalized()
				faces12.normals[indices[index1][index2]] = face12_smooth_normal
				if not faces12_normal.is_equal_approx(face12_smooth_normal):
					faces12.is_smooth_shaded = true

	var load_world_entity_wads := func() -> void:
		for entity in map_structure.classnames.get(settings.world_entity_classname, []):
			if entity.properties.has(settings.world_entity_wad_property):
				for path in entity.properties.get(settings.world_entity_wad_property, "").split(";", false):
					var wad_path := settings.game_wads_directory

					if path.is_absolute_path():
						wad_path = wad_path.path_join(path.get_file())
					elif path.is_relative_path():
						wad_path = wad_path.path_join(path.trim_prefix("/"))
					else:
						continue

					var wad := game_loader.load_wad(wad_path)
					if wad:
						map_structure.wads.append(wad)

	var load_materials_and_textures := func() -> void:
		var enable_base_material_features := func(material: BaseMaterial3D) -> void:
			for slot in BaseMaterial3D.TEXTURE_MAX:
				if not material.get_texture(slot):
					continue
				match slot:
					BaseMaterial3D.TEXTURE_EMISSION:
						material.set_feature(BaseMaterial3D.FEATURE_EMISSION, true)
					BaseMaterial3D.TEXTURE_NORMAL:
						material.set_feature(BaseMaterial3D.FEATURE_NORMAL_MAPPING, true)
					BaseMaterial3D.TEXTURE_RIM:
						material.set_feature(BaseMaterial3D.FEATURE_RIM, true)
					BaseMaterial3D.TEXTURE_CLEARCOAT:
						material.set_feature(BaseMaterial3D.FEATURE_CLEARCOAT, true)
					BaseMaterial3D.TEXTURE_FLOWMAP:
						material.set_feature(BaseMaterial3D.FEATURE_ANISOTROPY, true)
					BaseMaterial3D.TEXTURE_AMBIENT_OCCLUSION:
						material.set_feature(BaseMaterial3D.FEATURE_AMBIENT_OCCLUSION, true)
					BaseMaterial3D.TEXTURE_HEIGHTMAP:
						material.set_feature(BaseMaterial3D.FEATURE_HEIGHT_MAPPING, true)
					BaseMaterial3D.TEXTURE_SUBSURFACE_SCATTERING:
						material.set_feature(BaseMaterial3D.FEATURE_SUBSURFACE_SCATTERING, true)
					BaseMaterial3D.TEXTURE_SUBSURFACE_TRANSMITTANCE:
						material.set_feature(BaseMaterial3D.FEATURE_SUBSURFACE_TRANSMITTANCE, true)
					BaseMaterial3D.TEXTURE_BACKLIGHT:
						material.set_feature(BaseMaterial3D.FEATURE_BACKLIGHT, true)
					BaseMaterial3D.TEXTURE_REFRACTION:
						material.set_feature(BaseMaterial3D.FEATURE_REFRACTION, true)
					BaseMaterial3D.TEXTURE_DETAIL_ALBEDO | BaseMaterial3D.TEXTURE_DETAIL_NORMAL:
						material.set_feature(BaseMaterial3D.FEATURE_DETAIL, true)

		for material in map_structure.materials:
			var path := settings.game_materials_directory.path_join(material)
			var base_material: BaseMaterial3D = game_loader.load_base_material()
			var override_material: Material = game_loader.load_material(path)

			if override_material:
				override_material = override_material.duplicate()
				map_structure.materials[material].base = base_material
				map_structure.materials[material].override = override_material
			else:
				map_structure.materials[material].base = base_material
				map_structure.materials[material].override = null

			var slot_textures := {}
			var slot_name_textures := {}

			for slot in settings.shader_texture_slots:
				var slot_name: String = settings.shader_texture_slots[slot]
				var texture_suffix: String = settings.texture_suffixes[slot]

				# trying to load texture or textures for current slot
				path = settings.game_textures_directory.path_join(material + texture_suffix)
				var material_textures := game_loader.load_animated_textures(path, map_structure.wads)
				if not material_textures["textures"].size() and slot == BaseMaterial3D.TEXTURE_ALBEDO:
					path = settings.game_textures_directory.path_join(material)
					material_textures = game_loader.load_animated_textures(path, map_structure.wads)
				# skipping slot if no textures were found
				var textures: Array[Texture2D] = material_textures["textures"]
				if not textures.size():
					continue

				var texture_index: int = 0
				if textures.size() > 1:
					slot_textures[slot] = textures
					slot_name_textures[slot_name] = textures
					texture_index = material_textures["texture_index"]
					if not (texture_index >= 0 and texture_index < textures.size()):
						texture_index = 0

				# setting texture on the base and override materials
				base_material.set_texture(slot, textures[texture_index])
				if override_material:
					if override_material is BaseMaterial3D:
						override_material.set_texture(slot, textures[texture_index])
					elif override_material is ShaderMaterial:
						override_material.set_shader_parameter(slot_name, textures[texture_index])

			# enabling features on base materials if textures are provided
			enable_base_material_features.call(base_material)
			if override_material is BaseMaterial3D:
				enable_base_material_features.call(override_material)

			# saving alternative textures to material metadata
			if slot_textures.size():
				base_material.set_meta(settings.alternative_textures_metadata_property, slot_textures)
				if override_material:
					if override_material is BaseMaterial3D:
						override_material.set_meta(settings.alternative_textures_metadata_property, slot_textures)
					elif override_material is ShaderMaterial:
						override_material.set_meta(settings.alternative_textures_metadata_property, slot_name_textures)

	var generate_brush_geometry := func(thread_index: int) -> void:
		var brush := brush_structures[thread_index]
		var surface_tools := {}
		var skip_surface_tool: SurfaceTool
		var points := PackedVector3Array()
		var triangles := PackedVector3Array()
		var is_concave_mesh := false
		var skip_aabb := AABB()

		# creating surface tools from brush surfaces
		for face in brush.faces:
			var face_vertices := face.vertices
			var face_normal := face.plane.normal
			var vertices := face.get_vertices(brush.center, true)
			points.append_array(face.get_vertices(brush.center, false))
			var normals := face.get_normals(true)

			if face.skip:
				if not skip_surface_tool:
					skip_surface_tool = SurfaceTool.new()
					skip_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
				skip_surface_tool.add_triangle_fan(vertices)
				is_concave_mesh = true
				if not settings.skip_material_affects_collision:
					triangles.append_array(face.get_triangles(brush.center, true))
				continue
			triangles.append_array(face.get_triangles(brush.center, true))

			var face_material := face.material
			var material_name := face.material_name
			if not material_name in surface_tools:
				surface_tools[material_name] = SurfaceTool.new()
				surface_tools[material_name].begin(Mesh.PRIMITIVE_TRIANGLES)
				var material: Material = face_material.base
				if not settings.store_base_materials:
					material = face_material.get_material()
				surface_tools[material_name].set_material(material)

			# face base material always exists storing albedo texture
			var texture := face_material.base.get_texture(BaseMaterial3D.TEXTURE_ALBEDO)
			var texture_size := texture.get_size() if texture else Vector2.ZERO
			texture_size *= (1.0 / settings.unit_size)

			var uvs := PackedVector2Array()
			uvs.resize(vertices.size())
			if vertices.size() != face_vertices.size():
				uvs[0] = face.get_uv(vertices[0] + brush.center, texture_size)
				for index in range(1, vertices.size() - 1):
					uvs[index] = face.get_uv(face_vertices[index - 1], texture_size)
				uvs[vertices.size() - 1] = uvs[1]
			else:
				for index in range(vertices.size()):
					uvs[index] = face.get_uv(face_vertices[index], texture_size)

			var colors := PackedColorArray()
			colors.resize(vertices.size())
			colors.fill(Color.WHITE)

			if settings.store_barycentric_coordinates:
				# marking face vertices with colors
				colors[0] = Color.RED
				for index in range(1, colors.size()):
					if index % 2 == 1:
						colors[index] = Color.GREEN
					else:
						colors[index] = Color.BLUE

			var computed_colors := colors
			if settings.store_barycentric_coordinates:
				if settings.post_build_faces_colors_enabled:
					computed_colors = colors.duplicate()

			var is_post_colors := false
			if settings.post_build_faces_colors_enabled:
				var method := settings.post_build_faces_colors_method
				if post_build_script and post_build_script.has_method(method):
					var colors_size := colors.size()
					post_build_script.call(method, face, colors)
					if colors.size() != colors_size:
						push_warning("Failed setting face colors, array is resized!")
						colors.resize(colors_size)
						colors.fill(Color.WHITE)
					is_post_colors = true
					if settings.store_barycentric_coordinates:
						if colors == computed_colors:
							is_post_colors = false

			if not is_post_colors and settings.store_barycentric_coordinates and settings.use_advanced_barycentric_coordinates:
				# slicing face into triangles and marking them
				for index in range(1, vertices.size() - 1):
					var triangle_vertices: PackedVector3Array = []
					triangle_vertices.resize(3)
					triangle_vertices[0] = vertices[0]
					triangle_vertices[1] = vertices[index]
					triangle_vertices[2] = vertices[index + 1]

					var triangle_uvs: PackedVector2Array = []
					triangle_uvs.resize(3)
					triangle_uvs[0] = uvs[0]
					triangle_uvs[1] = uvs[index]
					triangle_uvs[2] = uvs[index + 1]

					var triangle_colors: PackedColorArray = []
					triangle_colors.resize(3)
					triangle_colors[0] = colors[0]
					triangle_colors[1] = colors[index]
					triangle_colors[2] = colors[index + 1]

					var triangle_normals: PackedVector3Array = []
					triangle_normals.resize(3)
					triangle_normals[0] = normals[0]
					triangle_normals[1] = normals[index]
					triangle_normals[2] = normals[index + 1]

					var triangle_type: int = 0
					if face_vertices.size() == 4:
						triangle_type = (2 | triangle_type)
					elif face_vertices.size() > 4:
						triangle_type = (2 | 4 | triangle_type)

					var n0 := not face_normal.is_equal_approx(triangle_normals[0])
					var n1 := not face_normal.is_equal_approx(triangle_normals[1])
					var n2 := not face_normal.is_equal_approx(triangle_normals[2])
					if n1 and n2:
						triangle_type = (1 | triangle_type)
					if n0 and n2:
						if triangle_colors[1] == Color.GREEN:
							triangle_type = (2 | triangle_type)
						elif triangle_colors[1] == Color.BLUE:
							triangle_type = (4 | triangle_type)
					if n0 and n1:
						if triangle_colors[2] == Color.GREEN:
							triangle_type = (2 | triangle_type)
						elif triangle_colors[2] == Color.BLUE:
							triangle_type = (4 | triangle_type)

					for color_index in range(triangle_colors.size()):
						triangle_colors[color_index].a = float(8 - triangle_type) / 8.0

					surface_tools[material_name].add_triangle_fan(triangle_vertices, triangle_uvs, triangle_colors, [], triangle_normals, [])
			else:
				surface_tools[material_name].add_triangle_fan(vertices, uvs, colors, [], normals, [])

		# indexing brush surface tools and also generating tangents
		for material in surface_tools:
			surface_tools[material].index()
			surface_tools[material].generate_tangents()
		if skip_surface_tool:
			skip_surface_tool.index()
			skip_aabb = skip_surface_tool.commit(brush.mesh).get_aabb()

		# creating brush array mesh from surface tools
		if surface_tools.size() > 0:
			brush.mesh = ArrayMesh.new()
			for material in surface_tools:
				brush.mesh = surface_tools[material].commit(brush.mesh)
				# material surface names are required for override materials
				var surface_index := brush.mesh.get_surface_count() - 1
				brush.mesh.surface_set_name(surface_index, material)

		# creating brush collision shapes
		if not brush.is_degenerate and points.size() > 0:
			brush.convex_shape = ConvexPolygonShape3D.new()
			brush.convex_shape.set_points(points)
			brush.shape = brush.convex_shape
		if triangles.size() > 0:
			brush.concave_shape = ConcavePolygonShape3D.new()
			brush.concave_shape.set_faces(triangles)
			if brush.is_degenerate:
				brush.shape = brush.concave_shape

		if settings.skip_material_enabled:
			if settings.skip_material_affects_collision:
				if brush.concave_shape and is_concave_mesh:
					brush.shape = brush.concave_shape

		# setting brush aabb from array mesh
		if brush.mesh:
			brush.aabb = brush.mesh.get_aabb()
			if brush.aabb.has_surface() and skip_aabb.has_surface():
				brush.aabb = brush.aabb.merge(skip_aabb)
			elif skip_aabb.has_surface():
				brush.aabb = skip_aabb
		elif skip_aabb.has_surface():
			brush.aabb = skip_aabb
		brush.aabb.position = brush.center - brush.aabb.size / 2.0
		brush.aabb.end = brush.center + brush.aabb.size / 2.0

	var generate_occluder := func(mesh: ArrayMesh) -> ArrayOccluder3D:
		if not mesh:
			return null
		var surface_tool := SurfaceTool.new()
		for surface_index in range(mesh.get_surface_count()):
			surface_tool.append_from(mesh, surface_index, Transform3D.IDENTITY)
		var arrays := surface_tool.commit_to_arrays()
		if arrays[Mesh.ARRAY_VERTEX] and arrays[Mesh.ARRAY_INDEX]:
			var occluder := ArrayOccluder3D.new()
			occluder.set_arrays(arrays[Mesh.ARRAY_VERTEX], arrays[Mesh.ARRAY_INDEX])
			return occluder
		else:
			return null

	var generate_lightmap_uv := func(mesh: ArrayMesh, transform: Transform3D, lightmap_scale: float = 1.0) -> void:
		if not mesh:
			return
		var surface_names: PackedStringArray = []
		surface_names.resize(mesh.get_surface_count())
		for surface_index in range(mesh.get_surface_count()):
			surface_names.set(surface_index, mesh.surface_get_name(surface_index))
		# BUG: lightmap unwrap creates new mesh without surface names
		# BUG: sometimes throws invalid index count errors when epsilon is too small
		mesh.lightmap_unwrap(transform, settings.lightmap_texel_size * (1.0 / lightmap_scale))
		for surface_index in range(mesh.get_surface_count()):
			mesh.surface_set_name(surface_index, surface_names[surface_index])

	var generate_brush_occluders := func(thread_index: int) -> void:
		var brush := brush_structures[thread_index]
		brush.occluder = generate_occluder.call(brush.mesh)

	var generate_brush_lightmap_uvs := func(thread_index: int) -> void:
		var brush := brush_structures[thread_index]
		var transform := Transform3D.IDENTITY.translated(brush.center)
		generate_lightmap_uv.call(brush.mesh, transform, 1.0)

	var generate_entity_bounds := func(thread_index: int) -> void:
		var entity := entity_structures[thread_index]
		for brush in entity.brushes:
			if not brush.aabb.has_surface():
				continue
			elif not entity.aabb.has_surface():
				entity.aabb = brush.aabb
			else:
				entity.aabb = entity.aabb.merge(brush.aabb)
		entity.center = entity.aabb.get_center()

	var generate_entity_meshes := func(thread_index: int) -> void:
		var entity := entity_structures[thread_index]
		var surface_tools := {}
		var shadow_mesh_surface_tools := {}
		var shadow_mesh_empty_surfaces := {}
		var has_shadow_mesh := false

		for brush in entity.brushes:
			if not brush.mesh:
				continue
			if brush.get_uniform_property(settings.override_material_metadata_properties.mesh_disabled, false):
				continue
			var cast_shadow := brush.get_uniform_property(settings.override_material_metadata_properties.cast_shadow, true)
			has_shadow_mesh = true if not cast_shadow else has_shadow_mesh

			var offset := Transform3D.IDENTITY.translated(brush.center - entity.center)
			for surface_index in range(brush.mesh.get_surface_count()):
				var surface_name := brush.mesh.surface_get_name(surface_index)
				var surface_material := brush.mesh.surface_get_material(surface_index)
				if not surface_name in surface_tools:
					surface_tools[surface_name] = SurfaceTool.new()
					surface_tools[surface_name].begin(Mesh.PRIMITIVE_TRIANGLES)
					surface_tools[surface_name].set_material(surface_material)
				surface_tools[surface_name].append_from(brush.mesh, surface_index, offset)

				if settings.shadow_meshes:
					if not surface_name in shadow_mesh_surface_tools:
						shadow_mesh_surface_tools[surface_name] = SurfaceTool.new()
						shadow_mesh_surface_tools[surface_name].begin(Mesh.PRIMITIVE_TRIANGLES)
						shadow_mesh_empty_surfaces[surface_name] = true
					if cast_shadow:
						shadow_mesh_surface_tools[surface_name].append_from(brush.mesh, surface_index, offset)
						shadow_mesh_empty_surfaces[surface_name] = false
		for material in surface_tools:
			surface_tools[material].index()

		if settings.shadow_meshes and has_shadow_mesh:
			var triangle := PackedVector3Array()
			triangle.resize(3) # hacking shadow mesh by inserting empty triangle
			triangle.fill(Vector3.ZERO) # making sure that array is zeroed
			for material in shadow_mesh_surface_tools:
				if shadow_mesh_empty_surfaces[material]:
					shadow_mesh_surface_tools[material].add_triangle_fan(triangle)
				shadow_mesh_surface_tools[material].index()

		if surface_tools.size():
			entity.mesh = ArrayMesh.new()
			for material in surface_tools:
				entity.mesh = surface_tools[material].commit(entity.mesh)
				# material surface names are required for override materials
				var surface_index := entity.mesh.get_surface_count() - 1
				entity.mesh.surface_set_name(surface_index, material)

			if settings.shadow_meshes and has_shadow_mesh:
				var flags := Mesh.ARRAY_FORMAT_VERTEX | Mesh.ARRAY_FORMAT_INDEX
				for material in shadow_mesh_surface_tools:
					entity.mesh.shadow_mesh = shadow_mesh_surface_tools[material].commit(entity.mesh.shadow_mesh, flags)
					var surface_index := entity.mesh.shadow_mesh.get_surface_count() - 1
					entity.mesh.shadow_mesh.surface_set_name(surface_index, material)

	var generate_entity_shapes := func(thread_index: int) -> void:
		var entity := entity_structures[thread_index]
		var points := PackedVector3Array()
		var triangles := PackedVector3Array()
		var convex_center := Vector3.ZERO
		var potentially_convex := false
		var shapes_amount := 0

		for brush in entity.brushes:
			if not brush.shape or not brush.concave_shape:
				continue
			if brush.get_uniform_property(settings.override_material_metadata_properties.collision_disabled, false):
				continue
			shapes_amount += 1
			var offset := Transform3D.IDENTITY.translated(brush.center - entity.center)
			if shapes_amount == 1 and brush.shape == brush.convex_shape:
				points = offset * brush.convex_shape.get_points()
				convex_center = brush.center
				potentially_convex = true
			var brush_triangles := brush.concave_shape.get_faces()
			triangles.append_array(offset * brush_triangles)

		if shapes_amount > 0:
			entity.concave_shape = ConcavePolygonShape3D.new()
			entity.concave_shape.set_faces(triangles)
			entity.shape = entity.concave_shape
		if shapes_amount == 1 and potentially_convex:
			entity.convex_shape = ConvexPolygonShape3D.new()
			entity.convex_shape.set_points(points)
			entity.shape = entity.convex_shape

	var generate_entity_occluders := func(thread_index: int) -> void:
		var entity := entity_structures[thread_index]
		var vertices := PackedVector3Array()
		var indices := PackedInt32Array()

		for brush in entity.brushes:
			if not brush.occluder:
				continue
			if brush.get_uniform_property(settings.override_material_metadata_properties.occluder_disabled, false):
				continue
			var last_vertices_size := vertices.size()
			vertices.append_array(brush.occluder.vertices)
			for index in range(last_vertices_size, vertices.size()):
				vertices[index] = vertices[index] + brush.center - entity.center
			var last_indices_size := indices.size()
			indices.append_array(brush.occluder.indices)
			if last_vertices_size != 0:
				for index in range(last_indices_size, indices.size()):
					indices[index] += last_vertices_size
		if vertices.size() and indices.size():
			entity.occluder = ArrayOccluder3D.new()
			entity.occluder.set_arrays(vertices, indices)

	var generate_entity_lightmap_uvs := func(thread_index: int) -> void:
		var entity := entity_structures[thread_index]
		var transform := Transform3D.IDENTITY.translated(entity.center)
		var lightmap_scale: float = 1.0
		if settings.lightmap_scale_property_enabled:
			lightmap_scale = entity.get_float_property(settings.lightmap_scale_property, 1.0)
			lightmap_scale = clampf(lightmap_scale, 0.0625, 16.0)
		generate_lightmap_uv.call(entity.mesh, transform, lightmap_scale)

	var generate_entity_nodes := func() -> void:
		for classname in map_structure.classnames:
			var class_builder: GDScript = null
			var path := settings.game_builders_directory.path_join(classname)
			class_builder = game_loader.load_script(path)
			if not class_builder:
				continue

			var class_root := Node3D.new()
			class_root.name = classname
			scene_root.add_child(class_root, settings.readable_node_names)

			for entity in map_structure.classnames[classname]:
				if class_builder.has_method("build"):
					entity.node = class_builder.call("build", map_structure, entity)
				if not entity.node:
					continue
				# setting node properties on created node
				for node_property in entity.node_properties:
					# checking node name property before setting
					if node_property == "name":
						var name: Variant = entity.node_properties[node_property]
						if name is String or name is StringName:
							if name.validate_node_name().strip_edges().is_empty():
								continue
					entity.node.set(node_property, entity.node_properties[node_property])
		# setting entity groups after creating all nodes
		for entity in map_structure.entities:
			if entity.node:
				for group_name in entity.node_groups:
					entity.node.add_to_group(group_name, true)

	var generate_scene_tree := func() -> void:
		for classname in map_structure.classnames:
			var class_root := scene_root.get_node_or_null(classname)

			for entity in map_structure.classnames[classname]:
				if not entity.node:
					continue

				# always using readable names for manually set node names
				if entity.parent and entity.parent.node:
					MapperUtilities.add_global_child(entity.node, entity.parent.node, settings)
				elif class_root:
					class_root.add_child(entity.node, settings.readable_node_names)

		# executing post build script after generating scene tree
		if post_build_script and post_build_script.has_method("build"):
			post_build_script.call("build", map_structure)

	var generate_scene_signals := func() -> void:
		for entity in entity_structures:
			if not entity.node:
				continue
			for signal_parameters in entity.signals:
				var destination_property: StringName = signal_parameters[0]
				var source_property: StringName = signal_parameters[1]
				var signal_name: StringName = signal_parameters[2]
				var method: StringName = signal_parameters[3]
				var classname: String = signal_parameters[4]
				var flags: int = signal_parameters[5]

				map_structure.bind_target_source_property(source_property)
				if not entity.node.has_signal(signal_name):
					continue
				if not destination_property in entity.properties:
					continue

				for map_entity in map_structure.target_sources[source_property].get(entity.properties[destination_property], []):
					if not map_entity.node:
						continue
					if not map_entity.node.has_method(method):
						continue
					if not map_entity.get_classname_property("").match(classname):
						continue

					var callable := Callable(map_entity.node, method)
					if not entity.node.is_connected(signal_name, callable):
						if entity.node.connect(signal_name, callable, flags | CONNECT_PERSIST) != OK:
							push_warning("Failed connecting signal, something is wrong!")

	var generate_scene_node_paths := func() -> void:
		for entity in entity_structures:
			if not entity.node:
				continue
			for entity_node in entity.node_paths:
				var destination_property: StringName = entity_node[0]
				var source_property: StringName = entity_node[1]
				var node_property: StringName = entity_node[2]
				var classname: StringName = entity_node[3]
				var is_first_node: bool = entity_node[4]

				map_structure.bind_target_source_property(source_property)
				if not destination_property in entity.properties:
					continue

				if is_first_node:
					for map_entity in map_structure.target_sources[source_property].get(entity.properties[destination_property], []):
						if not map_entity.node:
							continue
						if map_entity.get_classname_property("").match(classname):
							var node_path := entity.node.get_path_to(map_entity.node)
							entity.node.set(node_property, node_path)
							break
				else:
					var new_node_paths: Array[NodePath] = []
					var node_paths: Variant = entity.node.get(node_property)
					if node_paths != null and node_paths is Array[NodePath]:
						new_node_paths.append_array(node_paths)
					else:
						continue

					for map_entity in map_structure.target_sources[source_property].get(entity.properties[destination_property], []):
						if not map_entity.node:
							continue
						if map_entity.get_classname_property("").match(classname):
							var node_path := entity.node.get_path_to(map_entity.node)
							if not node_path in new_node_paths:
								new_node_paths.append(node_path)
					entity.node.set(node_property, new_node_paths)

	var set_scene_tree_owner := func() -> void:
		for node in scene_root.find_children("*", "", true, false):
			if not node.owner or node.owner.scene_file_path.is_empty():
				node.set_owner(scene_root)

	var pack_scene_tree := func() -> void:
		var error := packed_scene.pack(scene_root)
		# deleting scene tree from memory
		scene_root.free()
		if error != OK:
			push_error("Error packing scene tree, something is wrong!")
			packed_scene = null

	if print_progress:
		print("Starting building map %s" % [map.name])
	factory.call(generate_structures, 1, "Generating structures")
	factory.call(parallel_task.bind(generate_faces, face_structures.size()), 2, "Generating faces")
	factory.call(generate_materials, 3, "Generating materials")
	factory.call(parallel_task.bind(generate_brushes, brush_structures.size()), 4, "Generating brushes")

	if settings.warn_about_degenerate_brushes:
		var degenerate_brush_structure_amount: int = 0
		for brush_structure in brush_structures:
			if brush_structure.is_degenerate:
				degenerate_brush_structure_amount += 1
		if degenerate_brush_structure_amount > 0:
			push_warning("Found %s degenerate brushes, consider adjusting epsilon." % [degenerate_brush_structure_amount])

	if settings.smooth_shading_property_enabled:
		factory.call(parallel_task.bind(generate_smooth_entity_normals, smooth_entities.size()), 5, "Generating smooth entity normals")

	if settings.world_entity_wad_property_enabled:
		factory.call(load_world_entity_wads, 6, "Loading world entity wads")

	factory.call(load_materials_and_textures, 7, "Loading materials and textures")
	factory.call(parallel_task.bind(generate_brush_geometry, brush_structures.size()), 8, "Generating brush geometry")
	factory.call(parallel_task.bind(generate_entity_bounds, entity_structures.size()), 9, "Generating entity bounds")
	factory.call(parallel_task.bind(generate_entity_meshes, entity_structures.size(), false), 10, "Generating entity meshes")
	factory.call(parallel_task.bind(generate_entity_shapes, entity_structures.size()), 11, "Generating entity shapes")

	# BUG: creating array occluders is not thread safe
	if settings.occlusion_culling:
		factory.call(parallel_task.bind(generate_brush_occluders, brush_structures.size(), false), 12, "Generating brush occluders")
		# BUG: creating array occluders here should be thread safe, but memory errors are thrown
		factory.call(parallel_task.bind(generate_entity_occluders, entity_structures.size(), false), 13, "Generating entity occluders")

	# BUG: unwrapping array meshes for lightmaps is not thread safe
	if settings.lightmap_unwrap:
		factory.call(parallel_task.bind(generate_brush_lightmap_uvs, brush_structures.size(), false), 14, "Unwrapping brushes for lightmaps")
		factory.call(parallel_task.bind(generate_entity_lightmap_uvs, entity_structures.size(), false), 15, "Unwrapping entities for lightmaps")

	factory.call(generate_entity_nodes, 16, "Generating entity nodes")
	factory.call(generate_scene_tree, 17, "Generating scene tree")
	factory.call(generate_scene_signals, 18, "Generating scene signals")
	factory.call(generate_scene_node_paths, 19, "Generating scene node paths")
	factory.call(set_scene_tree_owner, 20, "Preparing to pack scene tree")
	factory.call(pack_scene_tree, 21, "Packing scene tree")
	if print_progress:
		print("Finished building map %s in %.3fs" % [map.name, (build_time / 1000.0)])

	# clearing out some leftover data
	game_loader.source_file = ""
	game_loader.custom_wads.clear()
	game_loader.animated_texture_cache.clear()
	game_loader.wad_cache.clear()
	game_loader.map_cache.clear()
	game_loader.mdl_cache.clear()

	return packed_scene


func build_mdl(mdl: MapperMdlResource) -> PackedScene:
	var packed_scene := PackedScene.new()
	var scene_root := Node3D.new()
	scene_root.name = mdl.name

	# obtaining normal table for mdl file
	var compressed_normals := MapperMdlResource.create_default_compressed_normals()

	# creating simple mdl material with first texture
	var material := game_loader.load_base_material()
	if mdl.textures.size():
		material.albedo_texture = mdl.textures[0]
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.metallic_specular = 0.0

	var mdl_frame_rate: float = settings.options.get("mdl_frame_rate", 10.0)
	var animation_nodes: Array[Node3D] = []
	var animations: Dictionary = {}

	var create_frame := func(frame: Dictionary, parent: Node3D) -> void:
		var vertices: PackedVector3Array = []
		var compressed_vertices: PackedInt32Array = frame["vertices"]
		vertices.resize(compressed_vertices.size() / 4)

		var normals: PackedVector3Array = []
		normals.resize(vertices.size())

		for index in range(0, compressed_vertices.size(), 4):
			var transformed_vertex := Vector3.ZERO
			transformed_vertex.x = compressed_vertices[index + 0]
			transformed_vertex.y = compressed_vertices[index + 1]
			transformed_vertex.z = compressed_vertices[index + 2]
			vertices[index / 4] = transformed_vertex * mdl.scale + mdl.translation
			normals[index / 4] = compressed_normals[compressed_vertices[index + 3]]

		for index in range(vertices.size()):
			vertices[index] = settings.basis * vertices[index] * (1.0 / settings.unit_size)
			normals[index] = (settings.basis * normals[index]).normalized()

		var surface_tool := SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface_tool.set_material(material)
		for index in range(0, mdl.triangles.size(), 4):
			var is_front_face := mdl.triangles[index + 0]
			var index1 := mdl.triangles[index + 1]
			var index2 := mdl.triangles[index + 2]
			var index3 := mdl.triangles[index + 3]

			var triangle_vertices: PackedVector3Array = []
			triangle_vertices.resize(3)
			triangle_vertices[0] = vertices[index1]
			triangle_vertices[1] = vertices[index2]
			triangle_vertices[2] = vertices[index3]

			var triangle_normals: PackedVector3Array = []
			triangle_normals.resize(3)
			triangle_normals[0] = normals[index1]
			triangle_normals[1] = normals[index2]
			triangle_normals[2] = normals[index3]

			var triangle_uvs: PackedVector2Array = []
			for uv_index in [index1, index2, index3]:
				var is_on_seam := mdl.texture_coordinates[uv_index * 3 + 0]
				var u := float(mdl.texture_coordinates[uv_index * 3 + 1]) / mdl.texture_size.x
				var v := float(mdl.texture_coordinates[uv_index * 3 + 2]) / mdl.texture_size.y
				triangle_uvs.append(Vector2(u + 0.5 * int(is_on_seam and not is_front_face), v))

			surface_tool.add_triangle_fan(triangle_vertices, triangle_uvs, [], [], triangle_normals, [])
		surface_tool.generate_tangents()
		surface_tool.index()

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = surface_tool.commit()
		parent.add_child(mesh_instance, true)
		mesh_instance.owner = scene_root

		var frame_name: String = frame.get("name", "")
		if not frame_name.is_empty():
			var animation_name := frame_name.rstrip("0123456789")
			var animation_frame := frame_name.trim_prefix(animation_name)
			if animation_frame.is_empty():
				animation_frame = "1"
			if not animation_name.is_empty():
				if not animation_name in animations:
					animations[animation_name] = {}
				animations[animation_name][animation_frame.to_int()] = mesh_instance
			mesh_instance.name = frame_name
		animation_nodes.append(mesh_instance)

	var create_animations := func(frame_rate: float) -> void:
		var animation_player := AnimationPlayer.new()
		scene_root.add_child(animation_player, true)
		scene_root.move_child(animation_player, 0)
		animation_player.root_node = animation_player.get_path_to(scene_root)
		var animation_player_root := scene_root
		animation_player.owner = scene_root

		var animation_library := AnimationLibrary.new()
		animation_player.add_animation_library("", animation_library)
		animation_player.autoplay = "RESET"

		for animation_name in animations:
			var animation_frames: Array = animations[animation_name].keys()
			if not animation_frames.size():
				continue
			animation_frames.sort()

			var animation := Animation.new()
			var first_frame: int = animation_frames[0]
			var last_frame: int = animation_frames[-1]
			animation.length = float(last_frame - first_frame) / frame_rate

			for animation_node in animation_nodes:
				var track_index := animation.add_track(Animation.TYPE_VALUE)
				animation.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)
				var track_path := "%s:visible" % [animation_player_root.get_path_to(animation_node)]
				animation.track_set_path(track_index, track_path)
				animation.track_set_imported(track_index, true)

				for frame in animation_frames:
					var key_time := float(frame - first_frame) / frame_rate
					var key_value: bool = (animations[animation_name][frame] == animation_node)
					animation.track_insert_key(track_index, key_time, key_value)

			#MapperUtilities.remove_repeating_animation_keys(animation)
			animation_library.add_animation(animation_name, animation)
		MapperUtilities.create_reset_animation(animation_player, animation_library)

	for frame in mdl.frames:
		if frame["type"] > 0:
			var group_node := Node3D.new()
			scene_root.add_child(group_node, true)
			group_node.owner = scene_root
			for group_frame in frame["frames"]:
				create_frame.call(group_frame, group_node)
		else:
			create_frame.call(frame, scene_root)
	create_animations.call(mdl_frame_rate)

	var error := packed_scene.pack(scene_root)
	scene_root.free()
	if error != OK:
		push_error("Error packing scene tree, something is wrong!")
		packed_scene = null

	return packed_scene
