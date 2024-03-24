extends GeneralMovementBody2D

@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var default_speed_x_min: float = 50
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var default_speed_x_max: float = 125

var _rotating_dir: int

var body: Node2D
var pos: Vector2

var respawn_delay: float
var respawn_offset: float
var center: Vector2


func _ready() -> void:
	# Sprite setting
	(func():
		if !sprite_node:
			for i in get_children():
				if i is AnimatedSprite2D or i is Sprite2D:
					sprite_node = i
					break
		if !_rotating_dir:
			_rotating_dir = [-1, 1].pick_random()
		if is_zero_approx(speed.x):
			speed.x = _rotating_dir * randf_range(default_speed_x_min, default_speed_x_max)
		if !_fancy_effects_enabled():
			scale.y = -scale.y
			speed.y /= 1.5
			speed.x /= 2
			gravity_scale /= 2.5
	).call_deferred()
	
	_center()
	var pos_to: Vector2 = (pos - center).project(Vector2.UP).rotated(global_rotation)
	
	if respawn_delay > 0:
		get_tree().create_timer(respawn_delay, false).timeout.connect(
			func() -> void:
				add_sibling(body)
				body.global_position = (
					center + pos_to.rotated(body.global_rotation) - Vector2.RIGHT \
					* body.leaving_direction * \
					(get_viewport_rect().size.x / 2 + 64 + respawn_offset)
				)
				queue_free()
		)


func _physics_process(delta: float) -> void:
	super(delta)
	
	if sprite_node:
		if _rotating_dir && _fancy_effects_enabled():
			sprite_node.rotation_degrees += 12 * 50 * _rotating_dir * delta
	
	if respawn_delay > 0:
		_center()
		return
	if !Thunder.view.screen_dir(global_position, get_global_gravity_dir(), 512):
		queue_free()


func _center() -> void:
	center = (
		get_viewport_transform().affine_inverse().get_origin() + get_viewport_rect().get_center()
	)


func _fancy_effects_enabled() -> bool:
	return SettingsManager.settings.quality != SettingsManager.QUALITY.MIN

func _get_gravity_angle() -> float:
	return PhysicsServer2D.body_get_direct_state(get_rid()).total_gravity.angle() - PI/2
