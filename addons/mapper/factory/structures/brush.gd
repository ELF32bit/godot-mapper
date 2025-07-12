class_name MapperBrush

var faces: Array[MapperFace]

var surfaces: Dictionary
var materials: Dictionary

var mesh: ArrayMesh
var is_degenerate := false
var lightmap_scale: float = 1.0
var concave_shape: ConcavePolygonShape3D
var convex_shape: ConvexPolygonShape3D
var shape: Shape3D
var occluder: ArrayOccluder3D
var center: Vector3
var aabb: AABB

var metadata: Dictionary
var factory: MapperFactory


func has_point(point: Vector3, epsilon: float) -> bool:
	for face in faces:
		if face.plane.is_point_over(point):
			if not face.plane.has_point(point, epsilon):
				return false
	return true


func get_planes(from_mesh: bool = true) -> Array[Plane]:
	var planes: Array[Plane] = []
	if mesh and from_mesh:
		for index in range(mesh.get_surface_count()):
			for face in surfaces.get(mesh.surface_get_name(index), []):
				planes.append(face.plane)
	else:
		for face in faces:
			planes.append(face.plane)
	return planes


func is_uniform(surface: String = "*") -> bool:
	if not mesh or mesh.get_surface_count() != 1:
		return false
	return mesh.surface_get_name(0).matchn(surface)


func get_uniform_property(property: StringName, default: Variant = null) -> Variant:
	if not is_uniform():
		return default
	var surface_name := mesh.surface_get_name(0)
	var override_material: Material = materials[surface_name].override
	if not override_material:
		return default
	return override_material.get_meta(property, default)


func get_uniform_property_list() -> PackedStringArray:
	if not is_uniform():
		return PackedStringArray()
	var surface_name := mesh.surface_get_name(0)
	var override_material: Material = materials[surface_name].override
	if not override_material:
		return PackedStringArray()
	return override_material.get_meta_list()


func get_min_point_penetration(point: Vector3, epsilon: float) -> Variant:
	var min_distance: float = INF
	for face in faces:
		var distance_to_plane := face.plane.distance_to(point)
		if distance_to_plane > epsilon:
			return null
		distance_to_plane = absf(clampf(distance_to_plane, -INF, 0.0))
		min_distance = minf(distance_to_plane, min_distance)
	if is_nan(min_distance):
		return null
	return min_distance


func get_max_point_penetration(point: Vector3, epsilon: float) -> Variant:
	var max_distance: float = INF
	for face in faces:
		var distance_to_plane := face.plane.distance_to(point)
		if distance_to_plane > epsilon:
			return null
		distance_to_plane = absf(clampf(distance_to_plane, -INF, 0.0))
		max_distance = maxf(distance_to_plane, max_distance)
	if is_nan(max_distance):
		return null
	return max_distance


func get_relative_point_penetration(point: Vector3, epsilon: float) -> Variant:
	var min_distance := get_min_point_penetration(point, epsilon)
	if min_distance == null:
		return null
	var max_distance := get_max_point_penetration(point, epsilon)
	if max_distance == null:
		return null
	return min_distance / max_distance


func generate_surface_distribution(surfaces: PackedStringArray, density: float, min_floor_angle: float = 0.0, max_floor_angle: float = 45.0, even_distribution: bool = false, world_space: bool = false, seed: int = 0, use_map_basis: bool = true) -> PackedVector3Array:
	var triangles := PackedVector3Array()
	var normals := PackedVector3Array()
	var distribution := PackedFloat32Array([0.0])

	# clamping input values and converting angles to radians
	var max_density := factory.settings.max_distribution_density
	if max_density >= 1.0:
		density = clampf(density, 0.0, pow(max_density, 2.0))
	elif max_density > 0.0:
		density = clampf(density, 0.0, pow(max_density, 1.0 / 2.0))
	else:
		density = 0.0
	if density == 0.0: # allowing small density values a chance
		return PackedVector3Array()

	min_floor_angle = deg_to_rad(clampf(min_floor_angle, 0.0, 180.0))
	max_floor_angle = deg_to_rad(clampf(max_floor_angle, 0.0, 180.0))
	var actual_min_floor_angle := minf(min_floor_angle, max_floor_angle)
	var actual_max_floor_angle := maxf(min_floor_angle, max_floor_angle)
	min_floor_angle = actual_min_floor_angle
	max_floor_angle = actual_max_floor_angle

	var floor_angle_range := max_floor_angle - min_floor_angle
	var offset := -center * float(not world_space)

	var up := Vector3.UP
	var forward := Vector3.FORWARD
	var inverse_basis := Basis.IDENTITY
	if use_map_basis:
		up = MapperUtilities.get_up_vector(factory.settings)
		forward = MapperUtilities.get_forward_vector(factory.settings)
		var forward_rotation := MapperUtilities.get_forward_rotation(factory.settings)
		inverse_basis = Basis(forward_rotation).inverse()
	var up_plane := Plane(up, 0.0)

	var get_triangle_area := func(a: Vector3, b: Vector3) -> float:
		return a.length() * b.length() * sin(a.angle_to(b)) / 2.0

	# collecting triangles and normals from matching brush surfaces
	var matching_brush_surfaces := PackedStringArray()
	for brush_surface in self.surfaces:
		for surface in surfaces:
			if brush_surface.matchn(surface):
				matching_brush_surfaces.append(brush_surface)
				break

	for brush_surface in matching_brush_surfaces:
		for face in self.surfaces[brush_surface]:
			# calculating face normal angle to up vector
			var angle: float = face.plane.normal.angle_to(up)
			# discarding some brush faces by angle to up vector
			if not is_equal_approx(angle, min_floor_angle):
				if not is_equal_approx(angle, max_floor_angle):
					if angle < min_floor_angle or angle > max_floor_angle:
						continue

			# calculating triangle weight based on angle to up vector
			var angle_weight: float = 0.0
			if not is_zero_approx(floor_angle_range):
				angle_weight = (angle - min_floor_angle) / floor_angle_range
			var weight: float = clampf(1.0 - angle_weight, 0.0, 1.0)
			weight = float(1.0 if even_distribution else sqrt(weight))

			var face_triangles: PackedVector3Array = face.get_triangles(Vector3.ZERO, true)
			triangles.append_array(face_triangles)

			for index in range(0, face_triangles.size(), 3):
				normals.append(face.plane.normal)

				# calculating triangle vectors and area
				var a := face_triangles[index + 1] - face_triangles[index]
				var b := face_triangles[index + 2] - face_triangles[index]
				var area: float = get_triangle_area.call(a, b)

				# appending weighted triangle area to the distribution
				distribution.append(distribution[-1] + area * weight)

	# creating random number generator with specified seed
	var random_number_generator := RandomNumberGenerator.new()
	random_number_generator.seed = seed

	# determining amount of points from density
	var transform_array := PackedVector3Array()
	transform_array.resize(int(distribution[-1] * density) * 4)
	for transform_index in range(transform_array.size() / 4):
		# generating random triangle index based on area distribution
		var r1 := random_number_generator.randf()
		var index := distribution.bsearch(r1 * distribution[-1]) - 1

		# need 2 random floats to get random point inside triangle
		var r2 := random_number_generator.randf()
		var r3 := random_number_generator.randf()

		# calculating triangle vectors and area
		var a := triangles[index * 3 + 1] - triangles[index * 3]
		var b := triangles[index * 3 + 2] - triangles[index * 3]
		var area := get_triangle_area.call(a, b)

		# calculating random point inside parallelogram
		var p := r2 * a + r3 * b

		# calculating areas from triangles starting in point
		var area1 := get_triangle_area.call(-p, a - p)
		var area2 := get_triangle_area.call(-p, b - p)
		var area3 := get_triangle_area.call(a - p, b - p)

		# sum of areas should match triangle area if the point is inside
		if not is_equal_approx(area1 + area2 + area3, area):
			p = (a + b) - p

		# creating basis with up axis equal to triangle normal
		var basis := inverse_basis
		if normals[index].is_equal_approx(-up):
			basis *= Basis(forward, PI)
		elif not normals[index].is_equal_approx(up):
			var up_rotation := Quaternion(normals[index], up)
			var direction := up_plane.project(normals[index]).normalized()
			if not direction.is_equal_approx(-forward):
				basis *= Basis(Quaternion(direction, forward) * up_rotation)
			else:
				basis *= Basis(Quaternion(up, PI) * up_rotation)

		# calculating origin
		var origin := (triangles[index * 3] + p)

		# adding basis and origin to transform array
		transform_array[transform_index * 4 + 0] = basis.x
		transform_array[transform_index * 4 + 1] = basis.y
		transform_array[transform_index * 4 + 2] = basis.z
		transform_array[transform_index * 4 + 3] = origin + offset

	return transform_array


func generate_volume_distribution(density: float, min_penetration: float = 0.0, max_penetration: float = INF, basis: Basis = Basis.IDENTITY, world_space: bool = false, seed: int = 0, use_map_basis: bool = true) -> PackedVector3Array:
	if not aabb.has_volume():
		return PackedVector3Array()
	var epsilon := factory.settings.epsilon / factory.settings.unit_size

	# clamping density and penetration range values
	var max_density := factory.settings.max_distribution_density
	if max_density >= 1.0:
		density = clampf(density, 0.0, pow(max_density, 3.0))
	elif max_density > 0.0:
		density = clampf(density, 0.0, pow(max_density, 1.0 / 3.0))
	else:
		density = 0.0

	min_penetration = clampf(min_penetration, 0.0, INF)
	max_penetration = clampf(max_penetration, 0.0, INF)
	var actual_min_penetration := minf(min_penetration, max_penetration)
	var actual_max_penetration := maxf(min_penetration, max_penetration)
	min_penetration = actual_min_penetration
	max_penetration = actual_max_penetration

	var has_penetration_range := bool(min_penetration != max_penetration)
	var offset := -center * float(not world_space)

	var inverse_basis := basis
	var forward_rotation := MapperUtilities.get_forward_rotation(factory.settings)
	if use_map_basis:
		inverse_basis = basis * Basis(forward_rotation).inverse()
	var aabb_center := aabb.get_center()

	# creating random number generator with specified seed
	var random_number_generator := RandomNumberGenerator.new()
	random_number_generator.seed = seed

	var transform_array := PackedVector3Array()
	for index in range(int(aabb.get_volume() * density)):
		var r1 := (random_number_generator.randf() - 0.5) * 2.0
		var r2 := (random_number_generator.randf() - 0.5) * 2.0
		var r3 := (random_number_generator.randf() - 0.5) * 2.0

		# generating points inside aabb and discarding points outside of brush
		var direction := Vector3(r1, r2, r3)
		if use_map_basis:
			direction = forward_rotation * direction
			direction = direction.clamp(-Vector3.ONE, Vector3.ONE)
		var point := aabb_center + direction * aabb.size / 2.0

		var brush_has_point := false
		if has_penetration_range:
			var min_point_penetration := get_min_point_penetration(point, epsilon)
			if min_point_penetration != null:
				if min_point_penetration >= min_penetration:
					if min_point_penetration <= max_penetration:
						brush_has_point = true
		else:
			brush_has_point = has_point(point, epsilon)

		if brush_has_point:
			transform_array.append(inverse_basis.x)
			transform_array.append(inverse_basis.y)
			transform_array.append(inverse_basis.z)
			transform_array.append(point + offset)

	return transform_array
