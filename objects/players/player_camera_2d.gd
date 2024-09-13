extends Camera2D
class_name PlayerCamera2D

var stop_blocking_edges: bool

@export var force_xscroll_off: bool = false
@export_subgroup("Autoscroll")
@export var stop_blocking_on_complete: bool = true
@export var enable_left_border_death: bool = true
@export var enable_right_border_death: bool = true

@onready var par: Node2D = get_parent()
@onready var player: Player = Thunder._current_player

var _shocking: int = 0
var _xscroll: float
@onready var ofs: Vector2 = offset


func _ready() -> void:
	Thunder._current_camera = self
	process_callback = CAMERA2D_PROCESS_PHYSICS
	make_current()
	teleport()
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	teleport.call_deferred()
	
	if !is_instance_valid(player): return
	
	if !force_xscroll_off && SettingsManager.settings.xscroll:
		var dont_move := int(player.is_on_wall() || player.warp != player.Warp.NONE || player.is_crouching)
		if abs(player.speed.x) > 200 && player.running && !par is PathFollow2D:
			var _dir: int = sign(player.left_right) if !player.is_sliding_accelerating else sign(player.speed.x)
			_xscroll += (2 - dont_move) * _dir * delta
		_xscroll = move_toward(_xscroll, 0, delta)
		_xscroll = clampf(_xscroll, -1.25, 1.25)
	
	if stop_blocking_on_complete && player.completed:
		stop_blocking_edges = true


func teleport(sync_position_only = false, reset_interpolation: bool = false) -> void:
	player = Thunder._current_player
	if !par is PathFollow2D && player:
		global_position = Vector2(Thunder._current_player.global_position)
		if reset_interpolation:
			reset_physics_interpolation()
			_xscroll = 0
	
	if sync_position_only: return
	
	if par is PathFollow2D:
		_screen_border_logic()
	
	_xscroll_logic()
	
	Thunder.view.cam_border.call_deferred()


func _screen_border_logic() -> void:
	if player && !stop_blocking_edges && ("_is_stage_ready" in Scenes.current_scene && Scenes.current_scene._is_stage_ready):
		var rot: float = get_viewport_transform().affine_inverse().get_rotation()
		var kc: KinematicCollision2D = null
		var left_col: bool
		var right_col: bool
		while !kc && player.get_global_transform_with_canvas().get_origin().x < 15:
			kc = player.move_and_collide(Vector2.RIGHT.rotated(rot))
			left_col = enable_left_border_death
			if player.velocity.dot(Vector2.LEFT.rotated(rot)) > 0:
				player.vel_set_x.call_deferred(0)
		while !kc && player.get_global_transform_with_canvas().get_origin().x > get_viewport_rect().size.x - 15:
			kc = player.move_and_collide(Vector2.LEFT.rotated(rot))
			left_col = false
			right_col = enable_right_border_death
			if player.velocity.dot(Vector2.RIGHT.rotated(rot)) > 0:
				player.vel_set_x.call_deferred(0)
		if kc && kc.get_collider() && (left_col || right_col):
			player.die()


func _xscroll_logic() -> void:
	if !SettingsManager.settings.xscroll:
		_xscroll = 0.0
		drag_horizontal_enabled = false
		drag_horizontal_offset = 0
	elif !force_xscroll_off && is_instance_valid(player):
		drag_horizontal_enabled = true
		drag_left_margin = 0.5
		drag_right_margin = 0.5
		drag_horizontal_offset = _xscroll / 1.25


func shock(duration: float, amplitude: Vector2, interval: float = 0.01) -> void:
	if _shocking == 0:
		ofs = offset
	_shocking += 1
	var tw: Tween = create_tween().set_loops(ceili(duration / interval))
	tw.tween_callback(
		func() -> void:
			offset = Vector2(
				randf_range(-amplitude.x, amplitude.x),
				randf_range(-amplitude.y, amplitude.y)
			)
	).set_delay(interval)
	tw.finished.connect(
		func() -> void:
			offset = ofs
			_shocking -= 1
	)


func shock_smooth(duration: int, time_scale: float = 1.0, interval: float = 0.01) -> void:
	if _shocking == 0:
		ofs = offset
	_shocking += 1
	var step: float = duration
	while step > 0:
		offset = Vector2(
			randf_range(-step, step) / 2,
			randf_range(-step, step) / 2
		)
		step -= 1 / time_scale
		if step <= 0:
			offset = ofs
			_shocking -= 1
		await get_tree().create_timer(interval, false).timeout
