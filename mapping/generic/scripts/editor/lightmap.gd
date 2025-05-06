@tool
extends LightmapGI


func _ready() -> void:
	visible = not Engine.is_editor_hint()
	if not light_data or not light_data.light_texture:
		visible = false
	if Engine.is_editor_hint():
		visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed():
	if not light_data.light_texture:
		visible = false
