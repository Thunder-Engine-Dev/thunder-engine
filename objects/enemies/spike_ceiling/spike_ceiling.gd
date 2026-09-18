extends VBoxContainer

const FALL = preload("res://engine/objects/enemies/spike_ceiling/sfx/fall.wav")

@export var activated_area: Rect2
@export var draw_area_rect: bool
@export_group("Spike Ceiling Behaviour")
@export var activation_time: float = 4.0
## Parent-space X (walls) or Y (ceiling/floor) the spike-edge center stops at before switching to state 3.
@export var bottom_line_position: float = 408.0
@export var falling_speed: float = 1.0
@export var reabilitation_delay: float = 2.0
@export var reabilitation_speed: float = 100.0

var _state: int = 0
var _sine: float
var _falling_vel: float

@onready var init_pos: Vector2 = position
@onready var timer: Timer = $Activation
@onready var block: TextureRect = $Sprite2D
@onready var spike: TextureRect = $Spike
@onready var area: Area2D = $Spike/Area2D

func _ready() -> void:
	resized.connect(_set_scale)
	_set_scale()
	_orient_textures()
	reset_physics_interpolation.call_deferred()


func _physics_process(delta: float) -> void:
	var player: Player = Thunder._current_player
	if player && activated_area && activated_area.has_point(player.global_position):
		if timer.is_stopped():
			timer.start(activation_time)
	elif !timer.is_stopped():
		_sine = 0
		timer.stop()
	
	if _state == 1 && !timer.is_stopped():
		_sine += 50 * delta
		position = init_pos + _fall_dir() * sin(_sine) * (_sine / 70.0)
	elif _state == 2:
		_falling_vel += falling_speed * 50 * delta
		var target_pos: Vector2 = _stop_target_position()
		position = position.move_toward(target_pos, _falling_vel * 50 * delta)
		if position == target_pos:
			_state = 3
			_falling_vel = 0
			Thunder._current_camera.shock_smooth(10, 5)
			Audio.play_1d_sound(FALL)
			await Thunder.timer(2.0).timeout
			_state = 4
	elif _state == 4:
		position = position.move_toward(init_pos, reabilitation_speed * delta)
		if position == init_pos:
			timer.start(activation_time)
			_state = 0


func _on_activation_timeout() -> void:
	match _state:
		0:
			_sine = 0
		1:
			_sine = 0
			position = init_pos
		_:
			return
	_state += 1


func _set_scale() -> void:
	var _size := Vector2(get_rect().size.x, spike.get_rect().size.y - 6)
	area.scale = _size
	area.position = _size / 2


func _orient_textures() -> void:
	# restore block shading after rotation, spikes will still point along local down
	var quarter: int = posmod(roundi(wrapf(get_global_transform().get_rotation(), 0.0, TAU) / (PI * 0.5)), 4)
	block.flip_h = quarter == 2 or quarter == 3
	block.flip_v = quarter == 1 or quarter == 2
	spike.flip_h = quarter == 2 or quarter == 3
	spike.flip_v = true


func _fall_dir() -> Vector2:
	var dir: Vector2 = get_transform().basis_xform(Vector2.DOWN)
	if dir.is_zero_approx():
		return Vector2.DOWN
	return dir.normalized()


func _is_horizontal() -> bool:
	var dir: Vector2 = _fall_dir()
	return abs(dir.x) > abs(dir.y)


func _leading_edge_center() -> Vector2:
	return get_transform() * Vector2(size.x * 0.5, size.y)


func _stop_target_position() -> Vector2:
	var leading: Vector2 = _leading_edge_center()
	var target: Vector2 = position
	if _is_horizontal():
		target.x += bottom_line_position - leading.x
	else:
		target.y += bottom_line_position - leading.y
	return target
