extends RichTextLabel

const TOGGLE_DOUBLE_PRESS_TIME: float = 0.3

var objects: Dictionary[Node2D, RID]
var draw_cols: Array[Dictionary]
var last_text: String
var draw_node: Node2D

var show_areas: bool
var show_tilemaps: bool
var show_collision: bool

var toggler_dict: Dictionary[String, KeyToggler] = {
	"shift": KeyToggler.new(),
	"ctrl": KeyToggler.new(),
	"alt": KeyToggler.new(),
}

func _input(event: InputEvent) -> void:
	if !Console.cv.object_names_shown:
		return
	if event is InputEventKey && !event.is_echo():
		if event.keycode == KEY_SHIFT:
			toggler_logic(event, toggler_dict.shift)
			if toggler_dict.shift.toggled:
				show_areas = !event.is_pressed()
			else:
				show_areas = event.is_pressed()
		
		elif event.keycode == KEY_CTRL:
			toggler_logic(event, toggler_dict.ctrl)
			if toggler_dict.ctrl.toggled:
				show_tilemaps = !event.is_pressed()
			else:
				show_tilemaps = event.is_pressed()
		
		elif event.keycode == KEY_ALT:
			toggler_logic(event, toggler_dict.alt)
			if toggler_dict.alt.toggled:
				show_collision = !event.is_pressed()
			else:
				show_collision = event.is_pressed()
			if is_instance_valid(draw_node):
				draw_node.queue_redraw()


func toggler_logic(event: InputEventKey, key: KeyToggler):
	key.timer = TOGGLE_DOUBLE_PRESS_TIME
	if key.progress % 2 == 0:
		if event.is_pressed():
			key.progress += 1
	else:
		if !event.is_pressed():
			key.progress += 1
	if key.progress >= 4:
		key.progress = 0
		key.toggled = !key.toggled
		var _find: int = toggler_dict.values().find(key)
		if _find >= 0:
			Console.print("[Debug] toggled " + str(toggler_dict.keys()[_find]) + " to " + str(key.toggled))


func __draw() -> void:
	if !show_collision: return
	const _color := Color(1.0, 0, 0, 0.6)
	for col: Dictionary in draw_cols:
		var outlined = col.collider
		var shape_id = col.shape
		
		var _rect: Rect2
		var _polygons: Array[PackedVector2Array]
		if outlined is TileMapLayer || outlined is TileMap:
			var coords = outlined.get_coords_for_body_rid(col.rid)
			var tile_data: TileData = outlined.get_cell_tile_data(coords)
			if !tile_data:
				continue
			var gl_pos = outlined.to_global(
				outlined.map_to_local(coords)
			)
			draw_node.draw_set_transform(gl_pos)
			for i in tile_data.get_collision_polygons_count(0):
				_polygons.append(tile_data.get_collision_polygon_points(0, i))
		elif outlined is CollisionObject2D:
			var owner_id = outlined.shape_find_owner(shape_id)
			draw_node.draw_set_transform_matrix(outlined.shape_owner_get_owner(owner_id).global_transform)
			for j in outlined.shape_owner_get_shape_count(owner_id):
				_rect = (outlined.shape_owner_get_shape(owner_id, j).get_rect())
			
		if _rect:
			draw_node.draw_rect(_rect, _color, false, 1.0, false)
		elif _polygons:
			for i in len(_polygons):
				_polygons[i].append(Vector2(_polygons[i][0].x, _polygons[i][0].y))
				draw_node.draw_polyline(_polygons[i], _color, 1.0)


func _physics_process(delta: float) -> void:
	if !Console.cv.object_names_shown:
		if visible: hide()
		return
	
	for i: KeyToggler in toggler_dict.values():
		i.timer = maxf(i.timer - delta, 0.0)
		if i.timer == 0.0 && i.progress > 0:
			i.progress = 0
	
	SettingsManager.show_mouse()
	
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
	
	var additional_options: String = "[color=dark_gray]"
	if show_tilemaps: additional_options += " (+T)"
	if show_areas: additional_options += " (+A)"
	if show_collision:
		additional_options += " (+C)"
		if !is_instance_valid(draw_node):
			draw_node = null
		if is_instance_valid(Scenes.current_scene):
			draw_node = Scenes.current_scene.get_node_or_null(^"DebugDrawNode")
			if draw_node:
				Thunder._connect(draw_node.draw, __draw, CONNECT_ONE_SHOT)
				draw_node.queue_redraw()
	
	text = "%.2v%s[/color]\n%s" % [global_mouse_pos, additional_options, last_text]
	
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
	draw_cols = []
	for i in results:
		var collider = i.collider
		if collider in dict.keys():
			continue
		if !collider || !collider is Node2D:
			continue
		if !show_tilemaps && (collider is TileMap || collider is TileMapLayer):
			continue
		dict[collider] = i.rid
		if show_collision:
			draw_cols.append(i)
	return dict


class KeyToggler:
	var toggled: bool = false
	var timer: float = 0.0
	var progress: int = 0
