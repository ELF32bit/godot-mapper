class_name MapperBrush

var faces: Array[MapperFace]

var surfaces: Dictionary
var materials: Dictionary

var mesh: ArrayMesh
var is_degenerate := false
var concave_shape: ConcavePolygonShape3D
var convex_shape: ConvexPolygonShape3D
var shape: Shape3D
var occluder: ArrayOccluder3D

var center: Vector3
var aabb: AABB

var factory: MapperFactory


func has_point(point: Vector3) -> bool:
	for face in faces:
		if face.plane.is_point_over(point):
			if not face.plane.has_point(point, factory.settings.epsilon):
				return false
	return true


func get_point_depth(point: Vector3) -> float:
	var min_distance: float = INF
	var max_distance: float = -INF
	for face in faces:
		var distance_to_plane := face.plane.distance_to(point)
		if distance_to_plane > factory.settings.epsilon:
			return NAN
		distance_to_plane = absf(distance_to_plane)
		min_distance = minf(distance_to_plane, min_distance)
		max_distance = maxf(distance_to_plane, max_distance)
	return min_distance / max_distance # can return NAN which is safe


func get_planes(from_mesh: bool = true) -> Array[Plane]:
	var planes: Array[Plane] = []
	if mesh and from_mesh:
		for index in range(mesh.get_surface_count()):
			for face in surfaces[mesh.surface_get_name(index)]:
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


func generate_surface_distribution(surfaces: PackedStringArray, density: float, spread: float = 0.0, min_scale: float = 1.0, max_scale: float = 1.0, min_floor_angle: float = 0.0, max_floor_angle: float = 45.0, even_distribution: bool = false, random_rotation: bool = true, world_space: bool = false, seed: int = 0) -> PackedVector3Array:
	var triangles := PackedVector3Array()
	var normals := PackedVector3Array()
	var distribution := PackedFloat32Array([0.0])

	# clamping input values and converting angles to radians
	density = clampf(density, 0.0, pow(factory.settings.max_populate_density, 2.0))

	min_floor_angle = deg_to_rad(clampf(min_floor_angle, 0.0, 180.0))
	max_floor_angle = deg_to_rad(clampf(max_floor_angle, 0.0, 180.0))
	var actual_min_floor_angle := minf(min_floor_angle, max_floor_angle)
	var actual_max_floor_angle := maxf(min_floor_angle, max_floor_angle)
	min_floor_angle = actual_min_floor_angle
	max_floor_angle = actual_max_floor_angle

	var actual_min_scale := minf(min_scale, max_scale)
	var actual_max_scale := maxf(min_scale, max_scale)
	min_scale = actual_min_scale
	max_scale = actual_max_scale

	var rotation_range := 2.0 * PI
	var scale_range := max_scale - min_scale
	var has_scale_range := (scale_range != 0.0)
	var floor_angle_range := max_floor_angle - min_floor_angle
	var offset := -center * float(not world_space)

	var get_triangle_area := func(a: Vector3, b: Vector3) -> float:
		return a.length() * b.length() * sin(a.angle_to(b)) / 2.0

	# collecting triangles and normals from matching brush surfaces
	for brush_surface in self.surfaces:
		for surface in surfaces:
			if brush_surface.matchn(surface):
				for face in self.surfaces[brush_surface]:
					# calculating face normal angle to up vector
					var angle: float = face.plane.normal.angle_to(Vector3.UP)
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
					weight = 1.0 if even_distribution else sqrt(weight)

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
				break

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

		# preparing to create basis
		var undefined_rotation := normals[index].is_equal_approx(Vector3.DOWN)
		var rotation_axis: Vector3 = (Vector3.DOWN if undefined_rotation else Vector3.UP)

		# creating basis with up axis equal to triangle normal
		var basis := Basis.IDENTITY
		if undefined_rotation:
			basis = basis.scaled(Vector3(1.0, -1.0, 1.0))
		else:
			basis = Basis(Quaternion(normals[index], Vector3.UP))

		# rotating basis around up axis by a random angle
		if random_rotation:
			var r4 := random_number_generator.randf()
			basis = basis.rotated(rotation_axis, rotation_range * r4)

		# scaling basis by a realitve random scale
		if has_scale_range:
			var r5 := random_number_generator.randf()
			basis = basis.scaled(Vector3.ONE * (min_scale + scale_range * r5))
		else:
			basis = basis.scaled(Vector3.ONE * min_scale)

		# calculating origin
		var origin := (triangles[index * 3] + p)

		# adding basis and origin to transform array
		transform_array[transform_index * 4 + 0] = basis.x
		transform_array[transform_index * 4 + 1] = basis.y
		transform_array[transform_index * 4 + 2] = basis.z
		transform_array[transform_index * 4 + 3] = origin + offset

	if spread > 0.0:
		return MapperUtilities.spread_transform_array(transform_array, spread)

	return transform_array


func generate_volume_distribution(density: float, spread: float = 0.0, min_scale: float = 1.0, max_scale: float = 1.0, min_depth: float = 0.0, max_depth: float = 1.0, random_rotation: bool = true, world_space: bool = false, seed: int = 0) -> PackedVector3Array:
	if not aabb.has_volume():
		return PackedVector3Array()

	# clamping density and depth range values
	density = clampf(density, 0.0, pow(factory.settings.max_populate_density, 3.0))

	min_depth = clampf(min_depth, 0.0, 1.0)
	max_depth = clampf(max_depth, 0.0, 1.0)
	var actual_min_depth := minf(min_depth, max_depth)
	var actual_max_depth := maxf(min_depth, max_depth)
	min_depth = actual_min_depth
	max_depth = actual_max_depth

	var actual_min_scale := minf(min_scale, max_scale)
	var actual_max_scale := maxf(min_scale, max_scale)
	min_scale = actual_min_scale
	max_scale = actual_max_scale

	var rotation_range := 2.0 * PI
	var scale_range := max_scale - min_scale
	var has_scale_range := (scale_range != 0.0)
	var has_depth_range := bool(max_depth - min_depth != 1.0)
	var offset := -center * float(not world_space)

	# creating random number generator with specified seed
	var random_number_generator := RandomNumberGenerator.new()
	random_number_generator.seed = seed

	var transform_array := PackedVector3Array()
	for index in range(int(aabb.get_volume() * density)):
		var r1 := random_number_generator.randf()
		var r2 := random_number_generator.randf()
		var r3 := random_number_generator.randf()

		# generating points inside aabb and discarding points outside of brush
		var point := aabb.position + aabb.size * Vector3(r1, r2, r3)

		var brush_has_point := false
		if has_depth_range:
			var point_depth := get_point_depth(point)
			if not is_nan(point_depth):
				if not (point_depth < min_depth or point_depth > max_depth):
					brush_has_point = true
		else:
			brush_has_point = has_point(point)

		if brush_has_point:
			var basis := Basis.IDENTITY
			if random_rotation:
				var r4 := random_number_generator.randf() - 0.5
				var r5 := random_number_generator.randf() - 0.5
				var r6 := random_number_generator.randf() - 0.5
				basis = Basis(Quaternion.from_euler(Vector3(r4, r5, r6) * rotation_range))
			if has_scale_range:
				var r7 := random_number_generator.randf()
				basis = basis.scaled(Vector3.ONE * (min_scale + scale_range * r7))
			else:
				basis = basis.scaled(Vector3.ONE * min_scale)

			transform_array.append(basis.x)
			transform_array.append(basis.y)
			transform_array.append(basis.z)
			transform_array.append(point + offset)

	if spread > 0.0:
		return MapperUtilities.spread_transform_array(transform_array, spread)

	return transform_array
