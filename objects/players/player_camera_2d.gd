extends Camera2D
class_name PlayerCamera2D

var stop_blocking_edges: bool

@export_subgroup("Autoscroll")
@export var stop_blocking_on_complete: bool = true
@export var enable_left_border_death: bool = true
@export var enable_right_border_death: bool = true

@onready var par: Node2D = get_parent()
@onready var player = Thunder._current_player

var _shocking: int = 0
var _old_speed: Vector2
@onready var ofs: Vector2 = offset

func _ready():
	Thunder._current_camera = self
	process_callback = CAMERA2D_PROCESS_IDLE #CAMERA2D_PROCESS_PHYSICS
	make_current()
	teleport()


func _physics_process(_delta):
	teleport()
	
	if is_instance_valid(player) && stop_blocking_on_complete && player.completed:
		stop_blocking_edges = true


func teleport() -> void:
	player = Thunder._current_player
	if !par is PathFollow2D && player:
		global_position = Vector2(Thunder._current_player.global_position)
	
	if par is PathFollow2D:
		if player && !stop_blocking_edges:
			var rot: float = get_viewport_transform().affine_inverse().get_rotation()
			var kc: KinematicCollision2D
			var left_col: bool
			var right_col: bool
			while !kc && player.get_global_transform_with_canvas().get_origin().x < 16:
				kc = player.move_and_collide(Vector2.RIGHT.rotated(rot))
				left_col = enable_left_border_death
				if player.velocity.dot(Vector2.LEFT.rotated(rot)) > 0:
					player.vel_set_x(0)
			while !kc && player.get_global_transform_with_canvas().get_origin().x > get_viewport_rect().size.x - 16:
				kc = player.move_and_collide(Vector2.LEFT.rotated(rot))
				left_col = false
				right_col = enable_right_border_death
				if player.velocity.dot(Vector2.RIGHT.rotated(rot)) > 0:
					player.vel_set_x(0)
			if kc && kc.get_collider() && (left_col || right_col):
				player.die()
	
	Thunder.view.cam_border.call_deferred()


func shock(duration: float, amplitude: Vector2, interval: float = 0.01) -> void:
	if _shocking == 0:
		ofs = offset
	_shocking += 1
	var tw: Tween = create_tween().set_loops(ceili(duration / interval)).set_trans(Tween.TRANS_ELASTIC)
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
