class_name MapperFace

var point1: Vector3
var point2: Vector3
var point3: Vector3
var material_name: String
var u_axis: Vector3
var v_axis: Vector3
var uv_shift: Vector2
var uv_valve: bool
var rotation: float
var scale: Vector2
var parameters: PackedInt64Array

var plane: Plane
var material: MapperMaterial
var vertices: PackedVector3Array
var normals: PackedVector3Array
var is_smooth_shaded := false
var center: Vector3
var skip := false

var factory: MapperFactory


func has_vertex(vertex: Vector3) -> bool:
	var epsilon := factory.settings.epsilon
	for face_vertex in vertices:
		if MapperUtilities.is_equal_approximately(vertex, face_vertex, epsilon):
			return true
	return false


func get_uv(global_vertex: Vector3, texture_size: Vector2, inverse_basis: Basis) -> Vector2:
	if uv_valve:
		return (Vector2(u_axis.dot(global_vertex), v_axis.dot(global_vertex)) / scale + uv_shift) / texture_size

	var vertex := inverse_basis * global_vertex
	var normal := (inverse_basis * plane.normal).abs()
	var uv := Vector2.ZERO

	if normal.z >= normal.y and normal.z >= normal.x:
		uv = Vector2(vertex.x, -vertex.y)
	elif normal.x >= normal.y and normal.x >= normal.z:
		uv = Vector2(vertex.y, -vertex.z)
	elif normal.y >= normal.x and normal.y >= normal.z:
		uv = Vector2(vertex.x, -vertex.z)

	return (uv.rotated(rotation) / scale + Vector2(uv_shift.x, uv_shift.y)) / texture_size


func get_vertices(origin: Vector3 = Vector3.ZERO, with_center: bool = false) -> PackedVector3Array:
	var transform := Transform3D.IDENTITY.translated(-origin)
	if with_center and vertices.size() > 4:
		var vertices_with_center := PackedVector3Array([center])
		vertices_with_center.append_array(vertices)
		vertices_with_center.append(vertices[0])
		return transform * vertices_with_center
	return transform * vertices


func get_normals(with_center: bool = false) -> PackedVector3Array:
	if with_center and normals.size() > 4:
		var average_normal := Vector3.ZERO
		for normal in normals:
			average_normal += normal
		average_normal = average_normal.normalized()
		var normals_with_center := PackedVector3Array([average_normal])
		normals_with_center.append_array(normals)
		normals_with_center.append(normals[0])
		return normals_with_center
	return normals


func get_triangles(origin: Vector3 = Vector3.ZERO, with_center: bool = true) -> PackedVector3Array:
	var vertices := get_vertices(origin, with_center)

	var triangles := PackedVector3Array()
	triangles.resize(3 * (vertices.size() - 2))

	for triangle_index in range(1, vertices.size() - 1):
		triangles[triangle_index * 3 - 3] = vertices[0]
		triangles[triangle_index * 3 - 2] = vertices[triangle_index]
		triangles[triangle_index * 3 - 1] = vertices[triangle_index + 1]

	return triangles
