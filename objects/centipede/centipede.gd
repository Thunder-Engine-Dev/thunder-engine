extends "res://engine/objects/platform/platform_path.gd"

@export_category("Centipede")
@export var moving_sound = preload("res://engine/objects/centipede/sfx/idle.wav")
@export var block_amount: int = 5
@export_group("Trigger", "trigger_")
@export var trigger_area_enabled: bool = true
@export var trigger_area: Rect2 = Rect2(0, 0, 32, 480)

@onready var audio_player = $Block/AudioStreamPlayer2D
@onready var spikeball = $Block/Spikeball
@onready var player = Thunder._current_player

var _set_delay: int = 32
@onready var _current_delay: int = 32
var _has_moved: bool = false
var _first_delay: bool = true
var _secondary_block: bool = false
var _latter: bool = false

var step_next_points: PackedVector2Array

func _ready():
	super()
	
	_sign_up_step_points()
	
	if _latter:
		_current_delay -= 1

func _physics_process(delta: float) -> void:
	super(delta)
	
	_rotate_spikeball(delta)
	
	if !player: return
	
	if trigger_area_enabled:
		_detect_area()
	
	if on_moving && !_has_moved:
		_has_moved = true
		if moving_sound:
			audio_player.stream = moving_sound
			audio_player.play()
	
	if on_moving:
		if _current_delay > 0:
			_current_delay -= speed * delta
			_movement_blocked = true
		else:
			_current_delay = 0
			_movement_blocked = false
			_process_stepper()
			if _first_delay:
				_first_delay = false
				_spawn_another_block()

func _detect_area() -> void:
	var actual_area: Rect2 = Rect2(global_position + trigger_area.position - trigger_area.size / 2, trigger_area.size)
	if actual_area.has_point(player.global_position) && !on_moving:
		_player_landed(player)

func _rotate_spikeball(delta: float) -> void:
	if !on_moving: return
	spikeball.rotation_degrees += 600 * delta

func _spawn_another_block() -> void:
	if block_amount < 2: return
	
	var cent = load(scene_file_path).instantiate()
	cent.progress = 0
	cent.block_amount = block_amount - 1
	cent.moving_sound = null
	cent.touching_player_touched_movement = false
	cent._secondary_block = true
	cent.speed = speed
	if _secondary_block:
		cent._latter = true
	
	get_parent().add_child(cent)

func _process_stepper() -> void:
	if !len(step_next_points): return
	if int(progress) / 2 == int(curve.get_closest_offset(step_next_points[0])) / 2:
		_current_delay = _set_delay
		_movement_blocked = true
		step_next_points.remove_at(0)

func _sign_up_step_points() -> void:
	for i in curve.point_count: step_next_points.append(curve.get_point_position(i))
	if speed < 0.0: step_next_points.reverse()
