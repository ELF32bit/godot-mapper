class_name MapperFaceResource
extends Resource

@export var point1: Vector3
@export var point2: Vector3
@export var point3: Vector3
@export var material: String
@export var u_axis: Vector3
@export var v_axis: Vector3
@export var uv_shift: Vector2
@export var uv_valve: bool
@export var rotation: float
@export var scale: Vector2
@export var parameters: PackedInt64Array


func _init(point1: Vector3 = Vector3.ZERO, point2: Vector3 = Vector3.ZERO, point3: Vector3 = Vector3.ZERO, material: String = "", u_axis: Vector3 = Vector3.ZERO, v_axis: Vector3 = Vector3.ZERO, uv_shift: Vector2 = Vector2.ZERO, uv_valve: bool = true, rotation: float = 0.0, scale: Vector2 = Vector2.ZERO, parameters: PackedInt64Array = PackedInt64Array()) -> void:
	self.point1 = point1
	self.point2 = point2
	self.point3 = point3
	self.material = material
	self.u_axis = u_axis
	self.v_axis = v_axis
	self.uv_shift = uv_shift
	self.uv_valve = uv_valve
	self.rotation = rotation
	self.scale = scale
	self.parameters = parameters


static func create_from_string(string: String) -> MapperFaceResource:
	var values := string.split(" ", false)

	if values.size() < 20:
		return null

	var u_axis: Vector3
	var v_axis: Vector3
	var uv_shift: Vector2
	var uv_valve: bool
	var rotation: float
	var scale: Vector2
	var parameters := PackedInt64Array()

	for index1 in [1, 6, 11]:
		for index2 in range(index1, index1 + 3):
			if not values[index2].is_valid_float():
				return null

	var point1 := Vector3(values[1].to_float(), values[2].to_float(), values[3].to_float())
	var point2 := Vector3(values[6].to_float(), values[7].to_float(), values[8].to_float())
	var point3 := Vector3(values[11].to_float(), values[12].to_float(), values[13].to_float())

	# spaces in material name not supported
	var material: String = values[15]

	if values[16] == "[":
		if values.size() < 30:
			return null

		for index in range(16, 30 + 1):
			if not index in [16, 21, 22, 27]:
				if not values[index].is_valid_float():
					return null

		u_axis = Vector3(values[17].to_float(), values[18].to_float(), values[19].to_float())
		v_axis = Vector3(values[23].to_float(), values[24].to_float(), values[25].to_float())
		uv_shift = Vector2(values[20].to_float(), values[26].to_float())
		uv_valve = true

		rotation = values[28].to_float()
		scale = Vector2(values[29].to_float(), values[30].to_float())

		for bitmask_index in range(31, values.size()):
			if values[bitmask_index].is_valid_int():
				parameters.append(values[bitmask_index].to_int())
	else:
		for index in range(16, 20 + 1):
			if not values[index].is_valid_float():
				return null

		uv_shift = Vector2(values[16].to_float(), values[17].to_float())
		uv_valve = false

		rotation = values[18].to_float()
		scale = Vector2(values[19].to_float(), values[20].to_float())

		for index in range(21, values.size()):
			if values[index].is_valid_int():
				parameters.append(values[index].to_int())

	return MapperFaceResource.new(point1, point2, point3, material, u_axis, v_axis, uv_shift, uv_valve, rotation, scale, parameters)
