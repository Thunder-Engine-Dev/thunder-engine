extends RichTextLabel

var objects: Array[Node2D]
var show_areas: bool
var show_tilemaps: bool

func _physics_process(delta: float) -> void:
	if !Console.cv.object_names_shown:
		if visible: hide()
		return
	
	SettingsManager.show_mouse()
	show_areas = Input.is_physical_key_pressed(KEY_SHIFT)
	show_tilemaps = Input.is_physical_key_pressed(KEY_CTRL)
	
	if !is_instance_valid(Scenes.current_scene) || !Scenes.current_scene.is_inside_tree():
		return
	
	objects = get_objects_under_mouse()
	var label_strings: PackedStringArray
	for node: Node2D in objects:
		if label_strings.size() >= 15:
			label_strings.append("<truncated>")
			break
		label_strings.append(node.name + ":\n\t[color=light_green]" + node.get_class() + "[/color]")
		#if node is TileMapLayer:
			#label_strings.append(
				#node.get_cell_atlas_coords(Vector2i(Scenes.current_scene.get_global_mouse_position() / 32))
			#)
		if node.scene_file_path:
			label_strings.append("\t[color=dark_gray]" + node.scene_file_path + "[/color]")
	
	if label_strings:
		text = "\n".join(label_strings)
	
	var mouse_pos := get_global_mouse_position()
	global_position = mouse_pos + Vector2(12, 0)
	if mouse_pos.x + 12 > get_viewport_rect().size.x - get_content_width() && mouse_pos.x - 4 - get_content_width() > 0:
		global_position.x = mouse_pos.x - get_content_width()
	
	modulate.a = 0.5 if !objects else 1.0


func get_objects_under_mouse() -> Array[Node2D]:
	var space_state := GlobalViewport.vp.get_world_2d().direct_space_state

	var query := PhysicsPointQueryParameters2D.new()
	query.position = Scenes.current_scene.get_global_mouse_position()
	if show_areas:
		query.collide_with_areas = true

	var results := space_state.intersect_point(query)
	var array: Array[Node2D]
	for i in results:
		var collider = i.collider
		if collider in array:
			continue
		if !collider || !collider is Node2D:
			continue
		if !show_tilemaps && (collider is TileMap || collider is TileMapLayer):
			continue
		array.append(collider)
	return array
