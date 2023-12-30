@icon("res://engine/scenes/map/textures/icons/branch_space.svg")
@tool
class_name BranchSpace extends Node2D

@export
var dot_texture: Texture2D
@export
var x_texture: Texture2D
@export
var next_space: BranchSpace : set = set_next_space, get = get_next_space 

@export
var draw_dots: bool = false : set = set_dot_draw, get = get_dot_draw

var _dot_draw: bool = false

var _next_space: BranchSpace

var dots: Array


signal changed

func _ready() -> void:
	add_to_group(&"marker_space")
	# Make sure that we in the editor
	if !Engine.is_editor_hint():
		return
	
	# Connect the signals to redraw connecting
	child_entered_tree.connect(_child_enter)
	child_exiting_tree.connect(_child_exited)
	
	# When seted to true '_notification' function will recive NOTIFICATION_TRANSFORM_CHANGED in message a.k.a "what"
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
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		changed.emit()

func _child_enter(child: Node) -> void:
	if child.is_in_group("map_marker"):
		if !child.changed.is_connected(item_changed):
			child.changed.connect(item_changed)
	queue_redraw()

func _child_exited(child: Node) -> void:
	if child.is_in_group("map_marker"):
		queue_redraw()

func _enter_tree() -> void:
	queue_redraw()

func _draw() -> void:
	if !Engine.is_editor_hint():
		return
	
	# Current child
	var child: Node2D
	
	# Draw lines
	for next_child: Node2D in get_children():
		# If not marker - skip
		if next_child.is_in_group("map_branch"):
			if child == null:
				child = next_child
				continue
			
			# Checks if rotation is near 90 deg
			var rot: float = child.global_position.direction_to(next_child.global_position).angle()
			var incorrect: bool = roundi(rad_to_deg(abs(rot))) % 90
			var modul: Color = Color.GREEN if !incorrect else Color.RED
			
			
			# draw line
			draw_line(child.global_position - global_position,next_child.global_position - global_position,modul,3)
			
			if_level_draw_x(child)
			
			child = next_child
			
	
	# same but with next Marker Space
	if next_space != null:
		var next_child = next_space.get_first_marker()
		if next_child == null: return
		
		var rot: float = child.global_position.direction_to(next_child.global_position).angle()
		var incorrect: bool = roundi(rad_to_deg(abs(rot))) % 90
		var modul: Color = Color.GREEN if !incorrect else Color.RED
		
		draw_line(child.global_position - global_position,next_child.global_position - global_position,modul,3)
		
		if_level_draw_x(child)
		
	if draw_dots && dot_texture != null:
		build_dots()
		for dot in dots:
			draw_texture(dot_texture,(dot - dot_texture.get_size()/2) - global_position)
	
	changed.emit()

func if_level_draw_x(mark: MapMarker) -> void:
	if mark.is_level() && x_texture != null:
		draw_texture(x_texture,(mark.global_position - (x_texture.get_size()/2)) - global_position)

# Returns first marker
func get_first_marker() -> MapMarker:
	for child in get_children():
		if child.is_in_group("map_marker"):
			return child
	
	return null

func get_level_markers() -> Array:
	var result: Array
	for child in get_children():
		if child.is_in_group("map_marker"):
			result.push_back(child)
	
	return result

func item_changed() -> void:
	queue_redraw()

func build_dots() -> void:
	dots.clear()
	var dot_intrval: float = 16
	
	var child: MapMarker
	for next_child: Node2D in get_children():
		if !next_child.is_in_group("map_marker"):
			continue
		
		if child == null:
			child = next_child as MapMarker
		
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
		
		child = next_child as MapMarker
	
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
func set_next_space(value: BranchSpace) -> void:
	# Avoid recursive
	if value == self:
		push_warning("[BranchSpace] Trying assign next marker space to self - rejected")
		return
	
	if _next_space != null:
		if _next_space.changed.is_connected(queue_redraw):
			_next_space.changed.disconnect(queue_redraw)
	
	_next_space = value
	
	if _next_space != null:
		_next_space.changed.connect(queue_redraw)
	queue_redraw()

func get_next_space() -> BranchSpace:
	return _next_space

func set_dot_draw(value: bool) -> void:
	_dot_draw = value
	queue_redraw()

func get_dot_draw() -> bool:
	return _dot_draw
