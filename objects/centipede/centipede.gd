extends StaticBody2D

const CentipedePathpoint := preload("centipede_pathpoint.gd")

@export_category("Centipede")
@export var moving_sound := preload("sfx/idle.wav")
@export var block_amount: int = 5
@export var speed: float = 100
@export_range(0.01, 20, 0.01, "suffix:s") var waiting: float = 0.25
@export_group("Path")
@export_node_path("Node2D") var centipede_pathpoints_path: NodePath = ^"CentipedePathpoints"
@export_group("Convey-belt Like")
@export var convey_belt_speed: Vector2
@export_group("Trigger", "trigger_")
@export var trigger_area_enabled: bool = true
@export var trigger_area: Rect2 = Rect2(0, 0, 32, 480)

@onready var audio_player = $AudioStreamPlayer2D
@onready var spikeball = $Spikeball
@onready var timer = $Timer
@onready var player = Thunder._current_player

@onready var centipede_pathpoints: Node2D = get_node(centipede_pathpoints_path)

var is_moving: bool
var _movement_blocked: bool = true
var _beginning: Vector2
var _has_moved: bool = false

var step_next_points: PackedVector2Array

@onready var running_speed: float = speed:
	set(value):
		running_speed = absf(value) * signf(running_speed)


func _ready() -> void:
	timer.timeout.connect(_start_moving)
	
	_sign_up_step_points()
	global_position = _beginning

func _process(delta: float) -> void:
	_rotate_spikeball(delta)

func _physics_process(delta: float) -> void:
	if is_instance_valid(player) && trigger_area_enabled:
		_detect_area()
	
	if !is_moving:
		return
	
	if !_has_moved:
		_has_moved = true
		timer.start(waiting + get_index() * 32.0 / speed)
		if moving_sound:
			audio_player.stream = moving_sound
			audio_player.play()
	
	if !_movement_blocked && !step_next_points.is_empty():
		var next := step_next_points[0]
		global_position = global_position.move_toward(next, speed * delta)
		if global_position.is_equal_approx(next):
			global_position = next
			step_next_points.remove_at(0)
			_movement_blocked = true
			timer.start(waiting)


func _sign_up_step_points() -> void:
	for i in centipede_pathpoints.get_children():
		if !i is CentipedePathpoint:
			continue
		step_next_points.append(i.global_position)
	if speed < 0.0:
		step_next_points.reverse()
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
	spikeball.rotation_degrees += 600 * delta
