@tool
class_name MarkerSpace extends Node2D

@export
var dot_texture: Texture2D
@export
var x_texture: Texture2D
@export
var next_space: MarkerSpace : set = set_next_space, get = get_next_space 

@export
var draw_dots: bool = false : set = set_dot_draw, get = get_dot_draw

var _dot_draw: bool = false

var _dots_drawn: bool = false

var _next_space: MarkerSpace

var dots: Array

var map: Node2D


signal changed

func _ready() -> void:
	if !Engine.is_editor_hint():
		map = Scenes.current_scene
	
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
			
			# Checks if rotation is near 90 deg
			var rot: float = child.global_position.direction_to(next_child.global_position).angle()
			var incorrect: bool = roundi(rad_to_deg(abs(rot))) % 90
			var modul: Color = Color.GREEN if !incorrect else Color.RED
			
			
			# draw line
			if Engine.is_editor_hint():
				draw_line(child.global_position - global_position,next_child.global_position - global_position,modul,3)
			
			if Engine.is_editor_hint():
				if_level_draw_x(child)
			else:
				if_level_make_x(child)
			
			child = next_child
			
	
	# same but with next Marker Space
	if next_space != null && next_space != self:
		var next_child = next_space.get_first_marker()
		if next_child == null: return
		
		var rot: float = child.global_position.direction_to(next_child.global_position).angle()
		var incorrect: bool = roundi(rad_to_deg(abs(rot))) % 90
		var modul: Color = Color.GREEN if !incorrect else Color.RED
		
		if Engine.is_editor_hint():
			draw_line(child.global_position - global_position,next_child.global_position - global_position,modul,3)
		
		if Engine.is_editor_hint():
			if_level_draw_x(child)
		else:
			if_level_make_x(child)
		
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

func if_level_draw_x(mark: MapPlayerMarker) -> void:
	if mark.is_level() && x_texture != null:
		draw_texture(x_texture,(mark.global_position - (x_texture.get_size()/2)) - global_position)
		
func if_level_make_x(mark: MapPlayerMarker) -> void:
	if mark.is_level() && x_texture != null:
		var m = map.get_node(map.player).x.instantiate()
		m.global_position = mark.global_position
		m.visible = mark.is_level_completed()
		map.add_child.call_deferred(m)

func make_dot(pos: Vector2) -> void:
	var m = map.get_node(map.player).dots.instantiate()
	m.global_position = pos
	m.visible = false
	map.add_child.call_deferred(m)

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

func item_changed() -> void:
	if !Engine.is_editor_hint(): return
	queue_redraw()

func build_dots() -> void:
	dots.clear()
	var dot_intrval: float = 16
	
	var child: MapPlayerMarker
	for next_child: Node2D in get_children():
		if !next_child.is_in_group("map_marker"):
			continue
		
		if child == null:
			child = next_child as MapPlayerMarker
		
		var length = child.global_position.distance_to(next_child.global_position)
		
		var amount = roundi(length / dot_intrval)
		
		var direction = child.global_position.direction_to(next_child.global_position)
		
		var computed_interval = length / amount
		
		for dot in range(amount):
			if dot == 0:
				if child.is_level():
					continue
			#var f_pos = child.global_position + direction * (dot * computed_interval)
			dots.push_back(child.global_position + direction * (dot * computed_interval))
		
		child = next_child as MapPlayerMarker
	
	if next_space != null:
		var next_child = next_space.get_first_marker()
		if next_child == null: return
		
		var length = child.global_position.distance_to(next_child.global_position)
		var amount = roundi(length / dot_intrval)
		var direction = child.global_position.direction_to(next_child.global_position)
		var computed_interval = length / amount
		
		for dot in range(amount):
			if dot == 0:
				if child.is_level():
					continue
			#var f_pos = child.global_position + direction * (dot * computed_interval)
			dots.push_back(child.global_position + direction * (dot * computed_interval))

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
