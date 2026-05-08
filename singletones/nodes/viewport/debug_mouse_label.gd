extends RichTextLabel

var objects: Dictionary[Node2D, RID]
var show_areas: bool
var show_tilemaps: bool
var last_text: String

func _physics_process(delta: float) -> void:
	if !Console.cv.object_names_shown:
		if visible: hide()
		return
	
	SettingsManager.show_mouse()
	show_areas = Input.is_physical_key_pressed(KEY_SHIFT)
	show_tilemaps = Input.is_physical_key_pressed(KEY_CTRL)
	
	if !is_instance_valid(Scenes.current_scene) || !Scenes.current_scene.is_inside_tree():
		return
	
	var global_mouse_pos: Vector2 = Scenes.current_scene.get_global_mouse_position()
	objects = get_objects_under(global_mouse_pos)
	
	var label_strings: PackedStringArray
	for node: Node2D in objects.keys():
		if label_strings.size() >= 15:
			label_strings.append("<truncated>")
			break
		label_strings.append(
			"[color=cyan]%s[/color]: [color=light_green]%s[/color]" % [
				node.name, node.get_class()
			]
		)
		if node is TileMapLayer:
			label_strings.append_array(
				_tile_map_layer_debug_logic(node, objects[node])
			)
		
		if node.scene_file_path:
			label_strings.append("\t[color=dark_gray]" + node.scene_file_path + "[/color]")
	
	if label_strings:
		last_text = "\n".join(label_strings)
	text = "%.2v\n%s" % [global_mouse_pos, last_text]
	
	var mouse_pos := get_global_mouse_position()
	global_position = mouse_pos + Vector2(15, 0)
	if (
		mouse_pos.x + 15 > get_viewport_rect().size.x - get_content_width() &&
		mouse_pos.x - 4 - get_content_width() > 0
	):
		global_position.x = mouse_pos.x - get_content_width()
	if (
		mouse_pos.y > get_viewport_rect().size.y - get_content_height() &&
		mouse_pos.y - get_content_height() > 0
	):
		global_position.y = mouse_pos.y - get_content_height()
	
	modulate.a = 0.5 if !objects else 1.0


func _tile_map_layer_debug_logic(node: Node2D, rid: RID) -> PackedStringArray:
	var label_strings: PackedStringArray
	var coords = node.get_coords_for_body_rid(rid)
	label_strings.append(
		"""\tSrcID: [color=yellow]%d[/color], \
Atlas: [color=yellow]%.v[/color], \
Alt: [color=yellow]%d[/color]""" % [
			node.get_cell_source_id(coords),
			node.get_cell_atlas_coords(coords),
			node.get_cell_alternative_tile(coords)
		]
	)
	if node.tile_set.get_custom_data_layers_count() > 0:
		var tile_data: TileData = node.get_cell_tile_data(coords)
		var layer_name = node.tile_set.get_custom_data_layer_name(0)
		if tile_data && tile_data.has_custom_data(layer_name):
			var custom_data = tile_data.get_custom_data(layer_name)
			var data_color = "light_green" if custom_data else "light_coral"
			label_strings.append(
				"\tTileData: [color=yellow]%s[/color]:\n\t\t[color=%s]%s[/color]" % [
					layer_name, data_color,
					tile_data.get_custom_data(layer_name)
				]
			)
	return label_strings


func get_objects_under(pos: Vector2) -> Dictionary[Node2D, RID]:
	var space_state := GlobalViewport.vp.get_world_2d().direct_space_state

	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	if show_areas:
		query.collide_with_areas = true

	var results := space_state.intersect_point(query)
	var dict: Dictionary[Node2D, RID]
	for i in results:
		var collider = i.collider
		if collider in dict.keys():
			continue
		if !collider || !collider is Node2D:
			continue
		if !show_tilemaps && (collider is TileMap || collider is TileMapLayer):
			continue
		dict[collider] = i.rid
	return dict
