class_name MapperMdlResource
extends Resource

const MAX_TEXTURES: int = 16
const MAX_TEXTURE_FRAMES: int = AnimatedTexture.MAX_FRAMES
const MAX_VERTICES: int = 1024
const MAX_TRIANGLES: int = 2048
const MAX_FRAMES: int = 256
const MAX_NORMALS: int = 162

@export var name: String

@export var scale: Vector3
@export var translation: Vector3
@export var bounding_radius: float
@export var eye_position: Vector3

@export var texture_size: Vector2i
@export var textures: Array[Texture2D]
@export var texture_coordinates: PackedInt32Array
@export var triangles: PackedInt32Array
@export var frames: Array[Dictionary]

@export var sync_type: int
@export var flags: int
@export var size: float


func _init(name: String = "", scale: Vector3 = Vector3.ZERO, translation: Vector3 = Vector3.ZERO, bounding_radius: float = 0.0, eye_position: Vector3 = Vector3.ZERO, texture_size: Vector2i = Vector2i.ZERO, textures: Array[Texture2D] = [], texture_coordinates: PackedInt32Array = [], triangles: PackedInt32Array = [], frames: Array[Dictionary] = [], sync_type: int = 0, flags: int = 0, size: float = 0.0) -> void:
	self.name = name
	self.scale = scale
	self.translation = translation
	self.bounding_radius = bounding_radius
	self.eye_position = eye_position
	self.texture_size = texture_size
	self.textures = textures
	self.texture_coordinates = texture_coordinates
	self.triangles = triangles
	self.frames = frames
	self.sync_type = sync_type
	self.flags = flags
	self.size = size


static func create_default_compressed_normals() -> PackedVector3Array:
	return PackedVector3Array([Vector3(-0.525731, 0.000000, 0.850651), Vector3(-0.442863, 0.238856, 0.864188), Vector3(-0.295242, 0.000000, 0.955423), Vector3(-0.309017, 0.500000, 0.809017), Vector3(-0.162460, 0.262866, 0.951056), Vector3(0.000000, 0.000000, 1.000000), Vector3(0.000000, 0.850651, 0.525731), Vector3(-0.147621, 0.716567, 0.681718), Vector3(0.147621, 0.716567, 0.681718), Vector3(0.000000, 0.525731, 0.850651), Vector3(0.309017, 0.500000, 0.809017), Vector3(0.525731, 0.000000, 0.850651), Vector3(0.295242, 0.000000, 0.955423), Vector3(0.442863, 0.238856, 0.864188), Vector3(0.162460, 0.262866, 0.951056), Vector3(-0.681718, 0.147621, 0.716567), Vector3(-0.809017, 0.309017, 0.500000), Vector3(-0.587785, 0.425325, 0.688191), Vector3(-0.850651, 0.525731, 0.000000), Vector3(-0.864188, 0.442863, 0.238856), Vector3(-0.716567, 0.681718, 0.147621), Vector3(-0.688191, 0.587785, 0.425325), Vector3(-0.500000, 0.809017, 0.309017), Vector3(-0.238856, 0.864188, 0.442863), Vector3(-0.425325, 0.688191, 0.587785), Vector3(-0.716567, 0.681718, -0.147621), Vector3(-0.500000, 0.809017, -0.309017), Vector3(-0.525731, 0.850651, 0.000000), Vector3(0.000000, 0.850651, -0.525731), Vector3(-0.238856, 0.864188, -0.442863), Vector3(0.000000, 0.955423, -0.295242), Vector3(-0.262866, 0.951056, -0.162460), Vector3(0.000000, 1.000000, 0.000000), Vector3(0.000000, 0.955423, 0.295242), Vector3(-0.262866, 0.951056, 0.162460), Vector3(0.238856, 0.864188, 0.442863), Vector3(0.262866, 0.951056, 0.162460), Vector3(0.500000, 0.809017, 0.309017), Vector3(0.238856, 0.864188, -0.442863), Vector3(0.262866, 0.951056, -0.162460), Vector3(0.500000, 0.809017, -0.309017), Vector3(0.850651, 0.525731, 0.000000), Vector3(0.716567, 0.681718, 0.147621), Vector3(0.716567, 0.681718, -0.147621), Vector3(0.525731, 0.850651, 0.000000), Vector3(0.425325, 0.688191, 0.587785), Vector3(0.864188, 0.442863, 0.238856), Vector3(0.688191, 0.587785, 0.425325), Vector3(0.809017, 0.309017, 0.500000), Vector3(0.681718, 0.147621, 0.716567), Vector3(0.587785, 0.425325, 0.688191), Vector3(0.955423, 0.295242, 0.000000), Vector3(1.000000, 0.000000, 0.000000), Vector3(0.951056, 0.162460, 0.262866), Vector3(0.850651, -0.525731, 0.000000), Vector3(0.955423, -0.295242, 0.000000), Vector3(0.864188, -0.442863, 0.238856), Vector3(0.951056, -0.162460, 0.262866), Vector3(0.809017, -0.309017, 0.500000), Vector3(0.681718, -0.147621, 0.716567), Vector3(0.850651, 0.000000, 0.525731), Vector3(0.864188, 0.442863, -0.238856), Vector3(0.809017, 0.309017, -0.500000), Vector3(0.951056, 0.162460, -0.262866), Vector3(0.525731, 0.000000, -0.850651), Vector3(0.681718, 0.147621, -0.716567), Vector3(0.681718, -0.147621, -0.716567), Vector3(0.850651, 0.000000, -0.525731), Vector3(0.809017, -0.309017, -0.500000), Vector3(0.864188, -0.442863, -0.238856), Vector3(0.951056, -0.162460, -0.262866), Vector3(0.147621, 0.716567, -0.681718), Vector3(0.309017, 0.500000, -0.809017), Vector3(0.425325, 0.688191, -0.587785), Vector3(0.442863, 0.238856, -0.864188), Vector3(0.587785, 0.425325, -0.688191), Vector3(0.688191, 0.587785, -0.425325), Vector3(-0.147621, 0.716567, -0.681718), Vector3(-0.309017, 0.500000, -0.809017), Vector3(0.000000, 0.525731, -0.850651), Vector3(-0.525731, 0.000000, -0.850651), Vector3(-0.442863, 0.238856, -0.864188), Vector3(-0.295242, 0.000000, -0.955423), Vector3(-0.162460, 0.262866, -0.951056), Vector3(0.000000, 0.000000, -1.000000), Vector3(0.295242, 0.000000, -0.955423), Vector3(0.162460, 0.262866, -0.951056), Vector3(-0.442863, -0.238856, -0.864188), Vector3(-0.309017, -0.500000, -0.809017), Vector3(-0.162460, -0.262866, -0.951056), Vector3(0.000000, -0.850651, -0.525731), Vector3(-0.147621, -0.716567, -0.681718), Vector3(0.147621, -0.716567, -0.681718), Vector3(0.000000, -0.525731, -0.850651), Vector3(0.309017, -0.500000, -0.809017), Vector3(0.442863, -0.238856, -0.864188), Vector3(0.162460, -0.262866, -0.951056), Vector3(0.238856, -0.864188, -0.442863), Vector3(0.500000, -0.809017, -0.309017), Vector3(0.425325, -0.688191, -0.587785), Vector3(0.716567, -0.681718, -0.147621), Vector3(0.688191, -0.587785, -0.425325), Vector3(0.587785, -0.425325, -0.688191), Vector3(0.000000, -0.955423, -0.295242), Vector3(0.000000, -1.000000, 0.000000), Vector3(0.262866, -0.951056, -0.162460), Vector3(0.000000, -0.850651, 0.525731), Vector3(0.000000, -0.955423, 0.295242), Vector3(0.238856, -0.864188, 0.442863), Vector3(0.262866, -0.951056, 0.162460), Vector3(0.500000, -0.809017, 0.309017), Vector3(0.716567, -0.681718, 0.147621), Vector3(0.525731, -0.850651, 0.000000), Vector3(-0.238856, -0.864188, -0.442863), Vector3(-0.500000, -0.809017, -0.309017), Vector3(-0.262866, -0.951056, -0.162460), Vector3(-0.850651, -0.525731, 0.000000), Vector3(-0.716567, -0.681718, -0.147621), Vector3(-0.716567, -0.681718, 0.147621), Vector3(-0.525731, -0.850651, 0.000000), Vector3(-0.500000, -0.809017, 0.309017), Vector3(-0.238856, -0.864188, 0.442863), Vector3(-0.262866, -0.951056, 0.162460), Vector3(-0.864188, -0.442863, 0.238856), Vector3(-0.809017, -0.309017, 0.500000), Vector3(-0.688191, -0.587785, 0.425325), Vector3(-0.681718, -0.147621, 0.716567), Vector3(-0.442863, -0.238856, 0.864188), Vector3(-0.587785, -0.425325, 0.688191), Vector3(-0.309017, -0.500000, 0.809017), Vector3(-0.147621, -0.716567, 0.681718), Vector3(-0.425325, -0.688191, 0.587785), Vector3(-0.162460, -0.262866, 0.951056), Vector3(0.442863, -0.238856, 0.864188), Vector3(0.162460, -0.262866, 0.951056), Vector3(0.309017, -0.500000, 0.809017), Vector3(0.147621, -0.716567, 0.681718), Vector3(0.000000, -0.525731, 0.850651), Vector3(0.425325, -0.688191, 0.587785), Vector3(0.587785, -0.425325, 0.688191), Vector3(0.688191, -0.587785, 0.425325), Vector3(-0.955423, 0.295242, 0.000000), Vector3(-0.951056, 0.162460, 0.262866), Vector3(-1.000000, 0.000000, 0.000000), Vector3(-0.850651, 0.000000, 0.525731), Vector3(-0.955423, -0.295242, 0.000000), Vector3(-0.951056, -0.162460, 0.262866), Vector3(-0.864188, 0.442863, -0.238856), Vector3(-0.951056, 0.162460, -0.262866), Vector3(-0.809017, 0.309017, -0.500000), Vector3(-0.864188, -0.442863, -0.238856), Vector3(-0.951056, -0.162460, -0.262866), Vector3(-0.809017, -0.309017, -0.500000), Vector3(-0.681718, 0.147621, -0.716567), Vector3(-0.681718, -0.147621, -0.716567), Vector3(-0.850651, 0.000000, -0.525731), Vector3(-0.688191, 0.587785, -0.425325), Vector3(-0.587785, 0.425325, -0.688191), Vector3(-0.425325, 0.688191, -0.587785), Vector3(-0.425325, -0.688191, -0.587785), Vector3(-0.587785, -0.425325, -0.688191), Vector3(-0.688191, -0.587785, -0.425325)])


static func load_from_file(path: String, palette: MapperPaletteResource = null) -> MapperMdlResource:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return null

	var ident := file.get_32()
	if ident != 1330660425:
		return null
	var version := file.get_32()
	if version != 6:
		return null

	var mdl := MapperMdlResource.new()
	mdl.name = path.get_file().trim_suffix("." + path.get_extension())

	mdl.scale.x = file.get_float()
	mdl.scale.y = file.get_float()
	mdl.scale.z = file.get_float()

	mdl.translation.x = file.get_float()
	mdl.translation.y = file.get_float()
	mdl.translation.z = file.get_float()

	mdl.bounding_radius = file.get_float()

	mdl.eye_position.x = file.get_float()
	mdl.eye_position.y = file.get_float()
	mdl.eye_position.z = file.get_float()

	var texture_amount := file.get_32()
	if texture_amount > MAX_TEXTURES:
		return null
	var texture_width := file.get_32()
	if texture_width == 0 or texture_width > 4096:
		return null
	var texture_height := file.get_32()
	if texture_height == 0 or texture_height > 4096:
		return null
	mdl.texture_size = Vector2i(texture_width, texture_height)
	var texture_size := texture_width * texture_height

	var vertices_amount := file.get_32()
	if vertices_amount > MAX_VERTICES:
		return null
	var triangles_amount := file.get_32()
	if triangles_amount > MAX_TRIANGLES:
		return null
	var frames_amount := file.get_32()
	if frames_amount > MAX_FRAMES:
		return null
	var texture_coordinates_amount := vertices_amount

	mdl.sync_type = file.get_32()
	mdl.flags = file.get_32()
	mdl.size = file.get_float()

	var file_palette: MapperPaletteResource = null
	if palette:
		file_palette = palette
	else:
		file_palette = MapperPaletteResource.create_default()

	var extract_texture := func() -> Texture2D:
		var indexed_colors := file.get_buffer(texture_size)
		var colors_rgb: PackedByteArray
		colors_rgb.resize(indexed_colors.size() * 3)
		for index in range(indexed_colors.size()):
			var color := file_palette.colors[indexed_colors[index]]
			colors_rgb[index * 3 + 0] = color.r8
			colors_rgb[index * 3 + 1] = color.g8
			colors_rgb[index * 3 + 2] = color.b8
		var image := Image.create_from_data(texture_width, texture_height, false, Image.FORMAT_RGB8, colors_rgb)
		var image_texture := ImageTexture.create_from_image(image)
		return image_texture

	var textures: Array[Texture2D] = []
	for texture_index in range(texture_amount):
		var is_animated := file.get_32()
		if is_animated:
			var texture_frames_amount := file.get_32()
			if texture_frames_amount > MAX_TEXTURE_FRAMES:
				return null

			var texture_frames_duration: PackedFloat32Array = []
			for index in range(texture_frames_amount):
				texture_frames_duration.append(file.get_float())

			var texture_frames: Array[Texture2D] = []
			for index in range(texture_frames_amount):
				texture_frames.append(extract_texture.call())

			var texture := AnimatedTexture.new()
			texture.frames = texture_frames_amount
			for index in range(texture.frames):
				texture.set_frame_texture(index, texture_frames[index])
				texture.set_frame_duration(index, texture_frames_duration[index])
			textures.append(texture)
		else:
			var texture := extract_texture.call()
			textures.append(texture)
	mdl.textures = textures

	var texture_coordinates: PackedInt32Array = []
	texture_coordinates.resize(texture_coordinates_amount * 3)
	for index in range(texture_coordinates_amount):
		texture_coordinates[index * 3 + 0] = file.get_32()
		texture_coordinates[index * 3 + 1] = file.get_32()
		texture_coordinates[index * 3 + 2] = file.get_32()
	mdl.texture_coordinates = texture_coordinates

	var triangles: PackedInt32Array = []
	triangles.resize(triangles_amount * 4)
	for index in range(triangles_amount):
		triangles[index * 4 + 0] = file.get_32()
		triangles[index * 4 + 1] = file.get_32()
		triangles[index * 4 + 2] = file.get_32()
		triangles[index * 4 + 3] = file.get_32()
	mdl.triangles = triangles

	var frames: Array[Dictionary] = []
	for index in range(frames_amount):
		var frame_type := file.get_32()

		var group_frame_amount: int = 1
		if frame_type:
			group_frame_amount = file.get_32()
		if not group_frame_amount < MAX_FRAMES:
			return null

		var bounding_box_min: PackedInt32Array
		for index2 in range(4):
			bounding_box_min.append(file.get_8())
		var bounding_box_max: PackedInt32Array
		for index2 in range(4):
			bounding_box_max.append(file.get_8())

		var frame_durations: PackedFloat32Array = []
		if frame_type:
			frame_durations.resize(group_frame_amount)
			for index2 in range(group_frame_amount):
				frame_durations[index2] = file.get_float()

		var frame: Dictionary = {}
		frame["type"] = frame_type
		frame["bounding_box_min"] = bounding_box_min
		frame["bounding_box_max"] = bounding_box_max
		if frame_type:
			frame["frame_durations"] = frame_durations
			frame["frames"] = []

		for index2 in range(group_frame_amount):
			var frame_data: Dictionary = {}
			if frame_type:
				var frame_bounding_box_min: PackedInt32Array
				for index3 in range(4):
					bounding_box_min.append(file.get_8())
				var frame_bounding_box_max: PackedInt32Array
				for index3 in range(4):
					bounding_box_max.append(file.get_8())
				frame_data["bounding_box_min"] = frame_bounding_box_min
				frame_data["bounding_box_max"] = frame_bounding_box_max
			var frame_name := file.get_buffer(16).get_string_from_ascii()
			frame_data["name"] = frame_name

			var frame_vertices: PackedInt32Array = []
			frame_vertices.resize(vertices_amount * 4)
			for index3 in range(vertices_amount):
				frame_vertices[index3 * 4 + 0] = file.get_8()
				frame_vertices[index3 * 4 + 1] = file.get_8()
				frame_vertices[index3 * 4 + 2] = file.get_8()
				frame_vertices[index3 * 4 + 3] = file.get_8()
				if not frame_vertices[index3 * 4 + 3] < MAX_NORMALS:
					return null
			frame_data["vertices"] = frame_vertices

			if frame_type:
				frame["frames"].append(frame_data)
			else:
				frame["name"] = frame_name
				frame["vertices"] = frame_vertices
		frames.append(frame)
	mdl.frames = frames

	return mdl
