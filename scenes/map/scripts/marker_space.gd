@icon("../textures/icons/branch_space.svg")
@tool
class_name MarkerSpace extends Node2D

@export var space_name: int
@export var dot_texture: Texture2D
@export var x_texture: Texture2D
@export var next_space: MarkerSpace : set = set_next_space, get = get_next_space 
@export var draw_dots: bool = false : set = set_dot_draw, get = get_dot_draw
@export var allow_saving: bool = true
@export_category("Progress Suspension")
@export var progress_continue_enabled: bool = true
@export var progress_title_prefix: String = "world\\n"
@export var progress_title_level: String = "{0} - {1}"
@export var progress_title_level_fallback: String = "x"

var _dot_draw: bool = false
var _dots_drawn: bool = false

var _next_space: MarkerSpace

var dots: Array
var dots_mapping = []
var total_levels: Array = []
var uncompleted_levels: Array[String] = []
var _stored_selected_marker: String

var map: Node2D

signal changed

func _init() -> void:
	if Engine.is_editor_hint(): return
	if allow_saving:
		if (
			Data.values.get("map_force_selected_marker") &&
			!Data.values.get("map_force_go_next") &&
			Data.values.get("map_force_old_marker")
		):
			_stored_selected_marker = Data.values.map_force_selected_marker
			Data.values.map_force_selected_marker = Data.values.map_force_old_marker
			print("[Map] Forced To Old Marker ", Data.values.map_force_selected_marker)


func _ready() -> void:
	if !Engine.is_editor_hint():
		map = Scenes.current_scene
		
		if Data.values.get("skip_progress_continue") == true:
			(func():
				Data.values.skip_progress_continue = false
			).call_deferred()
		elif SettingsManager.get_tweak("progress_continue", true) && progress_continue_enabled:
			_save_suspended_progress.call_deferred()
		
	
	# Connect the signals to redraw connecting
	child_entered_tree.connect(_child_enter)
	child_exiting_tree.connect(_child_exited)
	
	# When seted to true '_notification' function will recive NOTIFICATION_TRANSFORM_CHANGED in message a.k.a "what"
	if Engine.is_editor_hint():
		set_notify_transform(true)
	
	# Connects all childs position chainging for redrawing in editor lines
	for child in get_children():
		if child.is_in_group("map_marker"):
			child.changed.connect(item_changed)
	
	# To redraw in sync with next space
	if _next_space != null:
		if !_next_space.changed.is_connected(queue_redraw):
			_next_space.changed.connect(queue_redraw)
	
	if draw_dots:
		build_dots()
	
	if !Engine.is_editor_hint():
		if allow_saving && _stored_selected_marker:
			Data.values.map_force_selected_marker = _stored_selected_marker
		await get_tree().physics_frame
		if allow_saving && !uncompleted_levels.is_empty():
			_save_progress()


func _save_progress() -> void:
	var prof: ProfileManager.Profile = ProfileManager.current_profile as ProfileManager.Profile
	var next_level_name: String = uncompleted_levels[0].get_file().get_slice(".", 0)
	
	if Data.values.get("map_force_selected_marker") && Data.values.get("map_force_go_next"):
		Data.values.map_force_old_marker = Data.values.map_force_selected_marker
		Data.values.map_force_selected_marker = uncompleted_levels[0]
		print("[Map] Forced To ", Data.values.map_force_selected_marker)
		Data.values.map_force_go_next = false
	
	prof.set_next_level_name(next_level_name)
	var _no_save: bool = false
	var next_marker_id: int = get_next_marker_id(false) + 1
	var new_world: int = space_name
	var new_level: int = next_marker_id
	var world_numbers: PackedStringArray = prof.get_world_numbers().split("-")
	if world_numbers.size() > 1:
		if space_name > int(world_numbers[0]):
			new_world = space_name
			new_level = next_marker_id
		elif (
			next_marker_id > int(world_numbers[1]) &&
			int(space_name) >= int(world_numbers[0])
		):
			new_world = int(world_numbers[0])
			new_level = next_marker_id
		else:
			_no_save = true
			print("[Map] No save is needed")
	if !_no_save:
		prof.set_world_numbers(
			new_world,
			new_level
		)
		ProfileManager.save_current_profile()


func _save_suspended_progress() -> void:
	if ProfileManager.current_profile.data.get("executed") && !Console.cv.can_save_suspended_with_console:
		print("[Map] Suspended Save rejected due to enabled Console!")
		return
	var profile = ProfileManager.Profile.new()
	profile.name = "suspended"
	var pl_state: PlayerSuit = Thunder._current_player_state
	
	profile.data.saved_values = Data.values.duplicate(true)
	if pl_state:
		profile.data.saved_player_state = Thunder._current_player_state.name
	profile.data.remaining_continues = Data.technical_values.remaining_continues
	profile.data.custom_technical_values = Data.technical_values.custom_saved_values
	
	profile.data.saved_profile = ProfileManager.current_profile.name
	profile.data.saved_profile_data = ProfileManager.current_profile.data
	profile.data.title_prefix = progress_title_prefix
	
	var _saved_level: String = str(get_next_marker_id(false) + 1)
	if profile.data.saved_profile_data.get("star_world"):
		_saved_level = uncompleted_levels[0].get_file().get_slice(".", 0).right(1)
		if !_saved_level.is_valid_int():
			_saved_level = progress_title_level_fallback
	profile.data.title_level = progress_title_level.format([str(space_name), _saved_level])
	profile.data.scene = Scenes.current_scene.scene_file_path
	
	ProfileManager.profiles.suspended = profile
	ProfileManager.save_profile_data("suspended", profile.data)


# Recive events
func _notification(what: int) -> void:
	if !Engine.is_editor_hint(): return
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		changed.emit()

func _child_enter(child: Node) -> void:
	if !Engine.is_editor_hint(): return
	if child.is_in_group("map_marker"):
		if !child.changed.is_connected(item_changed):
			child.changed.connect(item_changed)
	queue_redraw()

func _child_exited(child: Node) -> void:
	if !Engine.is_editor_hint(): return
	if child.is_in_group("map_marker"):
		queue_redraw()

func _enter_tree() -> void:
	queue_redraw()

func _draw() -> void:
	if _dots_drawn: return
	# Current child
	var child: Node2D
	
	# Draw lines
	for next_child: Node2D in get_children():
		# If not marker - skip
		if next_child.is_in_group("map_marker"):
			if child == null:
				child = next_child
				continue
			
			draw_logic(child, next_child)
			
			child = next_child
	
	# same but with next Marker Space
	if next_space != null && next_space != self:
		var next_child = next_space.get_first_marker()
		if next_child == null: return
		
		draw_logic(child, next_child)
		
	if draw_dots && dot_texture != null:
		build_dots()
		for dot in dots:
			if Engine.is_editor_hint():
				draw_texture(dot_texture,(dot - dot_texture.get_size()/2) - global_position)
			else:
				make_dot(dot)
		if !Engine.is_editor_hint():
			_dots_drawn = true
	
	changed.emit()

func draw_logic(child: Node2D, next_child: Node2D) -> void:
	# Checks if rotation is near 90 deg
	var rot: float = child.global_position.direction_to(next_child.global_position).angle()
	var incorrect: bool = roundi(rad_to_deg(abs(rot))) % 90
	var modul: Color = Color.GREEN if !incorrect else Color.RED
	
	# Draw a line
	if Engine.is_editor_hint():
		draw_line(child.global_position - global_position,next_child.global_position - global_position,modul,3)
	
	# If in editor, it will be a plain sprite, but in game,
	# it will be an actual node with level information
	if Engine.is_editor_hint():
		if_level_draw_x(child)
	else:
		if_level_make_x(child)
		if next_child == get_last_marker():
			if_level_make_x(next_child)


func if_level_draw_x(mark: MapPlayerMarker) -> void:
	if mark.is_level() && x_texture != null:
		draw_texture(x_texture,(mark.global_position - (x_texture.get_size()/2)) - global_position)
		
func if_level_make_x(mark: MapPlayerMarker) -> void:
	if mark.is_level() && x_texture != null:
		total_levels.append(mark)
		var m = map.get_node(map.player).x.instantiate()
		m.global_position = mark.global_position
		m.visible = mark.is_level_completed()
		map.add_child.call_deferred(m)

func make_dot(pos: Vector2) -> void:
	var m = map.get_node(map.player).dots.instantiate()
	m.sprite_frames = map.dot_style
	m.offset = map.dot_sprite_offset
	m.global_position = pos
	m.visible = false
	map.add_child.call_deferred(m)
	
	var found: int = -1
	
	for i in len(dots_mapping):
		if dots_mapping[i][0].x == pos.x && dots_mapping[i][0].y == pos.y:
			found = i
	
	if found != -1:
		dots_mapping[found][1] = m

func make_dots_visible_before(current_marker: MapPlayerMarker) -> void:
	var found: int = -1
	var pos: Vector2 = current_marker.global_position
	
	for i in len(dots_mapping):
		var dot_pos = dots_mapping[i][0]
		#print(round(dot_pos.x / 32), " ", round(pos.x / 32), " : ", round(dot_pos.y / 32), " ", round(pos.y / 32))
		
		if (
			round(dot_pos.x / 32) == round(pos.x / 32) &&
			round(dot_pos.y / 32) == round(pos.y / 32) &&
			dots_mapping[i][1] is AnimatedSprite2D
		):
			found = i
			break
	
	while found >= 0:
		dots_mapping[found][1].visible = true
		found -= 1


func add_uncompleted_levels_after(marker: String) -> void:
	uncompleted_levels.clear()
	var switched_to_uncompleted: bool = false
	for i in total_levels:
		if Scenes.get_scene_path(i._level_save) == marker:
			switched_to_uncompleted = true
			continue
		if switched_to_uncompleted:
			uncompleted_levels.append(Scenes.get_scene_path(i._level_save))
	
	#print("Uncompleted levels:", uncompleted_levels)

func add_all_uncompleted_levels() -> void:
	if !uncompleted_levels.is_empty(): return
	for i in total_levels:
		if !i.get("_level_save"): continue
		uncompleted_levels.append(Scenes.get_scene_path(i._level_save))
	
	#print("Added all levels:", uncompleted_levels)


# Returns first marker
func get_first_marker() -> MapPlayerMarker:
	for child in get_children():
		if child.is_in_group("map_marker"):
			return child
	
	return null

func get_last_marker() -> MapPlayerMarker:
	var children = get_children()
	children.reverse()
	for child in children:
		if child.is_in_group("map_marker"):
			return child
	
	return null

func get_next_marker_id(count_non_levels: bool = true) -> int:
	var i: int = 0
	for child in get_children():
		if !child.is_in_group("map_marker"): continue
		if !count_non_levels && !child.count_as_level: continue
		if child.is_level() && child.is_level_completed():
			i += 1
	return i

func item_changed() -> void:
	if !Engine.is_editor_hint(): return
	queue_redraw()

func build_dots() -> void:
	dots.clear()
	
	var child: MapPlayerMarker
	for next_child: Node2D in get_children():
		if !next_child.is_in_group("map_marker"):
			continue
		
		if child == null:
			child = next_child as MapPlayerMarker
		
		dot_building_logic(child, next_child)
		
		child = next_child as MapPlayerMarker
	
	if next_space != null:
		var next_child = next_space.get_first_marker()
		if next_child == null: return
		
		dot_building_logic(child, next_child)

func dot_building_logic(child: MapPlayerMarker, next_child: Node2D) -> void:
	var dot_interval: float = 16
	
	var length = child.global_position.distance_to(next_child.global_position)
	var amount = roundi(length / dot_interval)
	var direction = child.global_position.direction_to(next_child.global_position)
	var computed_interval = length / amount
	
	for dot in range(amount):
		if dot == 0:
			if child.is_level():
				continue
		var f_pos = child.global_position + direction * (dot * computed_interval)
		dots.push_back(f_pos)
		dots_mapping.append([f_pos, child])


# Updates lines
func set_next_space(value: MarkerSpace) -> void:
	# Avoid recursive
	if value == self:
		push_warning(
			"[MarkerSpace] Trying to assign next marker space to itself - rejected"
		)
		return
	
	if value != null && &"next_space" in value && value.next_space == self:
		push_warning(
			"[MarkerSpace] Trying to recursively assign next marker space - rejected"
		)
		return
	 
	if _next_space != null:
		if _next_space.changed.is_connected(queue_redraw):
			_next_space.changed.disconnect(queue_redraw)
	
	_next_space = value
	
	if _next_space != null:
		_next_space.changed.connect(queue_redraw)
	queue_redraw()

func get_next_space() -> MarkerSpace:
	return _next_space

func set_dot_draw(value: bool) -> void:
	_dot_draw = value
	queue_redraw()

func get_dot_draw() -> bool:
	return _dot_draw
