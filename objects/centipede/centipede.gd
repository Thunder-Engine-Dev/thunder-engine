extends StaticBody2D

const CentipedePathpoint := preload("centipede_pathpoint.gd")

enum CentipedeTriggerType {
	TRIGGER_AREA,
	IMMEDIATE,
	NONE
}

@export_category("Centipede")
@export var moving_sound := preload("sfx/idle.wav")
@export var stop_sound_on_path_end: bool = true
@export var speed: float = 100
@export_range(0.01, 20, 0.01, "suffix:s") var waiting: float = 0.25
@export_group("Path")
@export_node_path("Node2D") var centipede_pathpoints_path: NodePath = ^"CentipedePathpoints"
@export var loop_path: bool = false
@export_group("Convey-belt Like")
@export var convey_belt_speed: Vector2
@export_group("Trigger", "trigger_")
@export var trigger_type: CentipedeTriggerType = CentipedeTriggerType.TRIGGER_AREA
@export var trigger_area_draw_enabled: bool = true:
	set(to):
		trigger_area_draw_enabled = to
		if Engine.is_editor_hint() && has_node("DrawArea"):
			$DrawArea.queue_redraw()
@export var trigger_area: Rect2 = Rect2(0, 0, 32, 480):
	set(to):
		trigger_area = to
		if Engine.is_editor_hint() && has_node("DrawArea"):
			$DrawArea.queue_redraw()

@onready var audio_player = $AudioStreamPlayer2D
@onready var spikeball = $Spikeball
@onready var timer = $Timer
@onready var player = Thunder._current_player

@onready var centipede_pathpoints: Node2D = get_node(centipede_pathpoints_path)

var is_moving: bool
var _movement_blocked: bool = true
var _beginning: Vector2
var _has_moved: bool = false
var _direction: int = 1

var step_next_points: PackedVector2Array
var initial_step_next_points: PackedVector2Array

@onready var running_speed: float = speed:
	set(value):
		running_speed = absf(value) * signf(running_speed)


func _ready() -> void:
	timer.timeout.connect(_start_moving)
	
	_sign_up_step_points()
	global_position = _beginning
	
	if trigger_type == CentipedeTriggerType.IMMEDIATE:
		is_moving = true

func _process(delta: float) -> void:
	_rotate_spikeball(delta)

func _physics_process(delta: float) -> void:
	if is_instance_valid(player) && trigger_type == CentipedeTriggerType.TRIGGER_AREA:
		_detect_area()
	
	if !is_moving:
		return
	
	if !_has_moved:
		_has_moved = true
		timer.start(waiting + get_index() * 32.0 / speed)
		if moving_sound:
			audio_player.stream = moving_sound
			audio_player.play()
	
	if !_movement_blocked:
		if loop_path && step_next_points.is_empty():
			_reset_step_points()
			global_position = _beginning
		
		if !loop_path && step_next_points.is_empty() && audio_player.playing && stop_sound_on_path_end:
			audio_player.stop()
		
		if !step_next_points.is_empty():
			var next := step_next_points[0]
			var old_pos = global_position
			global_position = global_position.move_toward(next, speed * delta)
			if global_position.is_equal_approx(next):
				global_position = next
				step_next_points.remove_at(0)
				_movement_blocked = true
				timer.start(waiting)
			else:
				_calculate_direction(old_pos, global_position)
	

func _sign_up_step_points() -> void:
	for i in centipede_pathpoints.get_children():
		if !i is CentipedePathpoint:
			continue
		step_next_points.append(i.global_position)
	if speed < 0.0:
		step_next_points.reverse()
	_beginning = step_next_points[0]
	initial_step_next_points = step_next_points.duplicate()
	step_next_points.remove_at(0)


func _reset_step_points() -> void:
	step_next_points = initial_step_next_points
	print(step_next_points)
	_beginning = step_next_points[0]
	step_next_points.remove_at(0)


func _detect_area() -> void:
	var actual_area: Rect2 = Rect2(global_position + trigger_area.position - trigger_area.size / 2, trigger_area.size)
	if actual_area.has_point(player.global_position) && !is_moving:
		_player_landed()


func _player_landed(p = null) -> void:
	is_moving = true

func _start_moving() -> void:
	_movement_blocked = false


func _rotate_spikeball(delta: float) -> void:
	if _movement_blocked:
		return
	spikeball.rotation_degrees += 600 * delta * _direction


func _calculate_direction(old_pos: Vector2, new_pos: Vector2) -> void:
	var motion_vector = new_pos - old_pos
	motion_vector = motion_vector.rotated(rotation)
	var dir_to_set = signi(motion_vector.x)
	if dir_to_set != 0:
		_direction = dir_to_set
