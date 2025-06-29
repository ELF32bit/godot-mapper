# Quake mapping plugin for Godot 4
![Preview](screenshots/preview.png)
Mapper plugin provides a way to manage game directories with map resources.<br>
Construct Godot scenes from maps using your own scripts and run them without the plugin.<br>
Organize map resources into game expansions by specifying alternative game directories.<br>

#### [Available in Godot Asset Library](https://godotengine.org/asset-library/asset/4016)
#### [Comprehensive Quake game profile for this plugin](https://github.com/ELF32bit/godot-mapper-quake)
#### [Additional tools for creating maps are available here](https://github.com/ELF32bit/mapping-tools)

## Features
* Progressive loading of complex maps as scenes in a deterministic way.
* Automatic loading of PBR textures, animated textures and shader material textures.
* Effortless brush entity construction and animation using plugin functions.
* Safe entity property parsing and binding, entity linking and grouping.
* **Ability to scatter grass on textures and barycentric wireframes!**
* Texture WAD and Palette support.
* Basic MDL support.

## Usage
### 1. Create game directory with map resources.
* game/builders for entity build scripts.
* game/materials for override materials with additional metadata.
* game/textures for textures with possible PBR or animation names.
* game/sounds for loading sounds with any of the supported extensions.
* game/maps for maps, also maps might embed each other in entity properties.
* game/mapdata for storing map lightmaps and navigation data.
* game/wads for additional texture WADs.
* game/mdls for animated models.

### 2. Construct map entities with build scripts.
Scripts inside builders directory are used to construct map entities.<br>
Entity classname property determines which build script the plugin will execute.<br>
Build scripts ending with underscore can be used to construct many similar entities.<br>
For example, trigger_.gd will be executed for trigger_once and trigger_multiple entities.<br>

#### MapperUtilities class provides smart build functions.
```GDScript
# func_breakable.gd will create individual brushes
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	return MapperUtilities.create_brush_entity(entity, "Node3D", "RigidBody3D")
```
```GDScript
# worldspawn.gd brushes will be merged into a single geometry
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	return MapperUtilities.create_merged_brush_entity(entity, "StaticBody3D")
```
```GDScript
# trigger_multiple.gd will create Area3D with a single merged collision shape
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	return MapperUtilities.create_merged_brush_entity(entity, "Area3D",
		false, true, false)
```
```GDScript
# func_decal.gd will create an improvised decal from a brush
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	return MapperUtilities.create_decal_entity(entity)
```
Create entity node or nodes, set a script with @export annotations and bind entity properties.<br>
Entity linking information is also avaliable, but linked entities might not be constructed yet.<br>
```GDScript
# light_.gd
var entity_target := map.get_first_entity_target(entity,
	"target", "targetname", "info_null")
if entity_target:
	entity_target.get_origin_property(null) # is available
	entity_target.node # is missing
```
Post build script named __post.gd can be executed after all entity nodes are constructed.<br>

### 3. Define map override materials with additional metadata.
Materials support the same naming pattern with underscore as build scripts.<br>
Moreover, material named WOOD_.tres will also apply to WOOD1, WOOD2, etc.<br>
Shader materials that use standard texture parameters will be assigned provided textures.<br>
For example, albedo_texture or normal_texture uniforms inside a shader.<br>

#### Material metadata can affect how nodes of uniform brushes are generated.
* ```mesh_disabled``` set to true will hide MeshInstance3D.<br>

> Meshes of uniform brushes will not be merged into entity mesh.

* ```cast_shadow``` set to false will disable shadow casting on MeshInstance3D.<br>

> Meshes of uniform brushes will be excluded from entity shadow mesh.

* ```gi_mode``` will set MeshInstance3D gi_mode to the specified mode.
* ```ignore_occlusion``` will disable occlusion culling for MeshInstance3D.
* ```collision_disabled``` set to true will disable CollisionShape3D.

> Shapes of uniform brushes will not be merged into entity collision shape.

* ```collision_layer``` will set CollisionObject3D layer to the specified layer.
* ```collision_mask``` will set CollisionObject3D mask to the specified mask.
* ```occluder_disabled``` set to true will hide OccluderInstance3D.

> Occluders of uniform brushes will not be merged into entity occluder.

* ```occluder_mask``` will set OccluderInstance3D mask to the specified mask.

Material metadata can be used to filter out special brushes.<br>
```GDScript
# WATER_.tres material
metadata/liquid = 1
metadata/mesh_disabled = true
metadata/collision_disabled = true
metadata/occluder_disabled = true

# worldspawn.gd (created as the merged brush entity)
for brush in entity.brushes:
	if not brush.get_uniform_property("liquid", 0) > 0:
		continue

	var liquid_area := MapperUtilities.create_brush(entity, brush, "Area3D")
	if not liquid_area:
		continue

	# manually re-enabling disabled brush nodes
	for child in liquid_area.get_children():
		if child is MeshInstance3D:
			child.visible = true
		elif child is CollisionShape3D:
			child.disabled = false
		elif child is OccluderInstance3D:
			child.visible = true

	MapperUtilities.add_global_child(liquid_area, entity_node, map.settings)
```

### 4. Animated textures and material alternative textures.
Generic textures are using complex naming pattern.<br>

#### Animated texture with 3 frames, possibly followed by PBR suffix.
* texture-0.png
* texture-1_albedo.png
* texture-2.png

> AnimatedTexture resource can be created alongside for more control.

#### Material alternative textures, possibly followed by animated texture suffix.
* texture+0.png
* texture+1-0.png
* texture+1-1_albedo.png
* texture+1-2.png
* texture+2_albedo.png

Quake textures with similar prefixes (+0, +1, +a, +b) can also be loaded.<br>
Plugin supports multiple loading schemes for various resources.<br>
Custom loader can be implemented for your own assets.<br>

### 5. Bind entity properties to node properties.
Simple entity properties can be bound to entity node properties.<br>
Assignment of node properties happens after entity node is constructed.<br>
```GDScript
entity.bind_int_property("hp", "health")
```
Sometimes it's necessary to modify entity properties before assigning.<br>
```GDScript
entity_node.health = entity.get_int_property("hp", 0) * 10.0
```
Complex entity properties like signals or node paths can also be bound.<br>
For example, trigger might need to send a kill signal to another entity.<br>
```GDScript
# trigger entity will send generic signal upon activation
entity.bind_signal_property("target", "targetname", "generic", "_on_generic_signal")
entity.bind_signal_property("killtarget", "targetname", "generic", "queue_free")
```
```GDScript
# path_corner entity will be storing an array of other path_corner targets
entity.bind_node_path_array_property("target", "targetname", "targets", "path_corner")
```
Common entity properties such as origin, angle, mangle are already bound.<br>

### 6. Assign navigation regions.
Various entities might affect navigation regions differently.<br>
Use entity node groups to manage entity navigation groups.<br>
```GDScript
# worldspawn.gd
var navigation_region := MapperUtilities.create_navigation_region(map, entity_node)
MapperUtilities.add_to_navigation_region(entity_node, navigation_region)

# func_detail entities will affect worldspawn navigation region
for map_entity in map.classnames.get("func_detail", []):
	MapperUtilities.add_entity_to_navigation_region(map_entity, navigation_region)
```

### 7. Generate surface and volume distributions.
Spread parameter will also filter out nearby points.
```GDScript
var grass_multimesh := preload("../resources/multimesh.tres")
var grass_transform_array := entity.generate_surface_distribution(
	["GRASS*", "__TB_empty"], 1.0, 0.25, 0.0, 60.0, false, false, 0)

MapperUtilities.scale_transform_array(grass_transform_array,
	Vector3(1.0, 1.0, 1.0), Vector3(1.5, 2.0, 1.5))
MapperUtilities.rotate_transform_array(grass_transform_array, true)

var grass_multimesh_instance := MapperUtilities.create_multimesh_instance(
	entity, entity_node, grass_multimesh, grass_transform_array)
```

## Examples
Check out provided examples to get a hang on API.<br>
Adjust plugin configuration inside **importers/map-scene.gd** file.<br>
Disable **editor/import/use_multiple_threads** for older versions of Godot.<br>
Restart Godot if the import process freezes during the first launch.<br>
Disable ```lightmap_unwrap``` setting if the freezes are consistent.<br>
