extends PathFollow2D

@export_category("Centipede")
@export var moving_sound = preload("res://engine/objects/centipede/sfx/idle.wav")
@export var block_amount: int = 5
@export var speed: float = 100
@export_group("Convey-belt Like")
@export var convey_belt_speed: Vector2
@export_group("Trigger", "trigger_")
@export var trigger_area_enabled: bool = true
@export var trigger_area: Rect2 = Rect2(0, 0, 32, 480)

@onready var block = $Block
@onready var audio_player = $Block/AudioStreamPlayer2D
@onready var spikeball = $Block/Spikeball
@onready var timer = $Block/Timer
@onready var player = Thunder._current_player

@onready var curve: Curve2D = (
	func() -> Curve2D:
		if !get_parent() is Path2D: return null
		return get_parent().curve
).call()
@onready var max_progress: float = (
	func() -> float:
		var max_length: float
		var current: float = progress_ratio
		progress_ratio = 1.0
		max_length = progress
		progress_ratio = current
		return max_length
).call()

var linear_velocity: Vector2
var final_progress: float

var is_moving: bool
var _movement_blocked: bool = true

var _set_delay: float = 32
var _current_delay: float = 32
var _has_moved: bool = false
var _first_delay: bool = true
var _secondary_block: bool = false
var _latter: bool = false

var step_next_points: PackedVector2Array

var vel: Vector2

var fixed_delta: float = 0.025
var progress_fixed: float
var prev_progress_fixed: float
var interpolation_timer: float

func _ready() -> void:
	var pro = progress_ratio
	progress_ratio = 1
	final_progress = progress
	progress_ratio = pro
	
	timer.wait_time = fixed_delta
	timer.timeout.connect(_process_fixed)
	
	v_offset += 0.01
	h_offset += 0.01
	
	_sign_up_step_points()
	
	if _latter:
		_current_delay -= 1


func _process(delta: float) -> void:
	_rotate_spikeball(delta)


func _physics_process(delta: float) -> void:
	if is_instance_valid(player) && trigger_area_enabled:
		_detect_area()
	
	if !is_moving || !get_parent().curve:
		return
	
	if !_has_moved:
		_has_moved = true
		timer.start(0.25 + get_index() * 32.0 / speed)
		if moving_sound:
			audio_player.stream = moving_sound
			audio_player.play()
	
	if _movement_blocked:
		return
	
	progress = move_toward(progress, final_progress, speed * delta)
	#interpolation_timer += 1 / (1 / delta * fixed_delta)
	
	# TODO: fix turning
	if global_position.distance_squared_to(get_parent().global_transform.affine_inverse() * step_next_points[0]) < (32 / speed) ** 2 + 8:
		global_position = step_next_points[0]
		step_next_points.remove_at(0)
		
		is_moving = false
		timer.start(0.25)
		await timer.timeout
		is_moving = true


func _process_fixed() -> void:
	_movement_blocked = false


func _detect_area() -> void:
	var actual_area: Rect2 = Rect2(global_position + trigger_area.position - trigger_area.size / 2, trigger_area.size)
	if actual_area.has_point(player.global_position) && !is_moving:
		_player_landed()


func _player_landed(p = null) -> void:
	is_moving = true


func _rotate_spikeball(delta: float) -> void:
	if _movement_blocked:
		return
	spikeball.rotation_degrees += 600 * delta


func _sign_up_step_points() -> void:
	for i in curve.point_count:
		step_next_points.append(curve.get_point_position(i))
	if speed < 0.0:
		step_next_points.reverse()
	step_next_points.remove_at(0)
