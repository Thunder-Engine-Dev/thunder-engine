extends GeneralMovementBody2D

@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var default_speed_x_min: float = 50
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var default_speed_x_max: float = 125

#@onready var _original_global_rot: float = global_rotation

#var _sprite_rot_init: bool
var _rotating_dir: int

@onready var quality: SettingsManager.QUALITY = SettingsManager.settings.quality


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
	
	var tw: Tween = create_tween()
	tw.tween_interval(6)
	tw.tween_property(self, ^"modulate:a", 0, 0.5)
	await tw.finished
	queue_free()


func _physics_process(delta: float) -> void:
	super(delta)
	
	if sprite_node:
		if _rotating_dir && _fancy_effects_enabled():
			sprite_node.rotation_degrees += 12 * 50 * _rotating_dir * delta
	
	if !Thunder.view.screen_dir(global_position, get_global_gravity_dir(), 512):
		queue_free()


func _fancy_effects_enabled() -> bool:
	return SettingsManager.settings.quality != SettingsManager.QUALITY.MIN

func _get_gravity_angle() -> float:
	return PhysicsServer2D.body_get_direct_state(get_rid()).total_gravity.angle() - PI/2
