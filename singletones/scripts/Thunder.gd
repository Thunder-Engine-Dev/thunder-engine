# This class provides helper and utility functions

extends Node

## Main singleton of Thunder Engine[br]
## Most information is stored in the signleton, like current player and its state,
## default gravity speed and some other functions you can use for your game

## Discarded, please see [signal "engine/singletones/scripts/Scenes.gd".scene_changed]
signal stage_changed

## Used to get access to [Thunder.View] subsingleton
var view: View = View.new() # View subsingleton
## Default gravity speed
var gravity_speed: float = 50
var _target_speed: int = 50

# TO GET CURRENT CAMERA, USE Viewport.get_camera_2d()

## Current player you are playing
var _current_player: Player: # Reference to the current player
	set(node):
		assert(is_instance_valid(node) && (node is Player), "Player node is invalid")
		_current_player = node
	get:
		assert(is_instance_valid(_current_player) && (_current_player is Player), "Player node is invalid or not set")
		return _current_player

var _current_player_state: PlayerStateData: # Current state of the player
	set(data):
		_current_player_state = data
		_current_player._on_power_state_change(data)

var _current_hud: CanvasLayer: # Reference to level HUD
	set(node):
		assert(is_instance_valid(node) && (node is CanvasLayer), "HUD node is invalid")
		_current_hud = node
	get:
		assert(is_instance_valid(_current_hud) && (_current_hud is CanvasLayer), "HUD node is invalid or not set")
		return _current_hud

## Get an [code]key[/code] from [code]obj[/code], this won't send any errors if there is no such key in the object
func get_or_null(obj: Variant, key: String):
	if !is_instance_valid(obj) || !obj.get(key): return null
	return obj[key]

## Find a child of [code]ref[/code] by [code]name[/code] of its class and return it or null
func get_child_by_class_name(ref: Node, name: String) -> Node:
	for child in ref.get_children():
		if child.is_class(name): return child
	return null

## Get relative FPS by inputting delta in [method Node._process] or [method Node._physics_process]
func get_delta(delta: float) -> float:
	return _target_speed * delta


func _init() -> void:
# warning-ignore:narrowing_conversion
	var rate: int = int(DisplayServer.screen_get_refresh_rate())
	if rate < 119:
		Engine.physics_ticks_per_second = rate * 2
		print(&"Using double fps for physics")
	else:
		Engine.physics_ticks_per_second = rate
	
	# Setting minimum window dimensions
	DisplayServer.window_set_min_size(Vector2i(640, 480))

## Discarded, see [method "engine/singletones/scripts/Scenes.gd".switch_to_scene]
func goto_scene(path) -> void:
	call_deferred(&"_deferred_goto_scene", path)

func _deferred_goto_scene(path) -> void:
	Scenes.current_scene.free()
	
	var s = load(path)
	Scenes.current_scene = s.instantiate()
	stage_changed.emit()
	
	if !Scenes.current_scene.is_inside_tree():
		get_tree().root.add_child(Scenes.current_scene)

## Add lives for [member _current_player][br]
## [color=orange][b]Note:[/b][/color] The [code]count[/code] you input must be between 1 and 10, or an error will be sent to console. 
## So if you want to cut down the lives, please code:[br]
## [code]Data.values.lives -= some_count[/code]
func add_lives(count: int):
	if count <= 0 or count > 10:
		push_error("[Thunder Engine] add_lives: Invalid life count. Must be between 1 and 10")
		return
	
	Data.values.lives += count
	ScoreTextLife.new("%sUP" % count, _current_player)

## Add scores for [member _current_player][br]
## [color=orange][b]Note:[/b][/color] The [code]count[/code] you input must be greater than 0, or an error will be sent to console.
## So if you want to cut down the scores, please code:[br]
## [code]Data.values.score -= some_count[/code]
func add_score(count: int):
	if count <= 0:
		push_error("[Thunder Engine] add_score: Invalid score count. Must be greater than 0")
		return
	
	Data.values.score += count
	ScoreText.new(str(count), _current_player)

## Compare current player power with [member power]
func is_player_power(power: Data.PLAYER_POWER) -> bool:
	return _current_player_state.player_power == power

## Subsingleton of ["engine/singletones/scripts/Thunder.gd"] to majorly manage functions related to screen borders and the detection of them
class View:
	## Current screen border, used [Rect2i] because the size and position of screen border don't support [float]
	var border: Rect2i
	## Current transformation of viewport
	var trans: Transform2D
	
	## Update [member border] and [member trans] for detectional functions, you need to call this method
	## in [method Node._process] or [method Node.__physics_process] to get better use of it
	func cam_border() -> void:
		var cam: Camera2D = Thunder.get_viewport().get_camera_2d()
		trans = cam.get_viewport_transform()
		border.size = Vector2i(cam.get_viewport_rect().size)
		border.position = Vector2i(cam.get_screen_center_position() - border.size/2.0)
	
	## Returns [code]true[/code] if given [code]pos[/code] is NOT out of left edge of screen
	func screen_left(pos: Vector2, offset: float) -> bool:
		return (trans * pos).x > -offset
	
	## Returns [code]true[/code] if given [code]pos[/code] is NOT out of right edge of screen
	func screen_right(pos: Vector2, offset: float) -> bool:
		return (trans * pos).x < border.size.x + offset
	
	## Returns [code]true[/code] if given [code]pos[/code] is NOT out of top edge of screen
	func screen_top(pos: Vector2, offset: float) -> bool:
		return (trans * pos).y > -offset
	
	## Returns [code]true[/code] if given [code]pos[/code] is NOT out of bottom edge of screen
	func screen_bottom(pos: Vector2, offset: float) -> bool:
		return (trans * pos).y < border.size.y + offset
	
	## Returns [code]true[/code] if given [code]pos[/code] is out of the edge of screen, which is decided by
	## [code]dir[/code] given
	func screen_dir(pos: Vector2, dir: Vector2, offset: float) -> bool:
		var ang: float = dir.angle()
		if ang > 3*PI/4 || ang < -3*PI/4:
			return screen_left(pos, offset)
		elif ang >= -3*PI/4 && ang <= -PI/4:
			return screen_top(pos, offset)
		elif ang > -PI/4 && ang < PI/4:
			return screen_right(pos, offset)
		else:
			return screen_bottom(pos, offset)
			
