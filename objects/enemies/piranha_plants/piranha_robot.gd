extends Node2D

const SOUND: AudioStream = preload("res://engine/objects/enemies/piranha_plants/sounds/robot.mp3")

@export_category("Robot Piranha")
@export var stay_in_pipe_at_first: bool = true
@export var range_in_pipe: float = 50.0
@export var stretching_speed: float = 150.0
@export var stretching_length: float = 60.0

var step: int

@onready var vision: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

@onready var stretching_end: Vector2 = position
@onready var stretching_start: Vector2 = stretching_end + (Vector2.DOWN * stretching_length).rotated(rotation)

signal shrinked_in
signal stretched_out


func _ready() -> void:
	if stay_in_pipe_at_first: position = stretching_start
	else: step = 2


func _physics_process(delta: float) -> void:
	var speed: float = stretching_speed * delta
	var player: Node2D = Thunder._current_player
	var ppos: Vector2 = global_transform.affine_inverse().basis_xform(player.global_position if player else Vector2.ZERO)
	var spos: Vector2 = global_transform.affine_inverse().basis_xform(global_position)
	var mario_near: bool = vision.is_on_screen() && player && abs(spos.x - ppos.x) <= range_in_pipe
	var up_or_down: bool = (mario_near && stay_in_pipe_at_first) || (!mario_near && !stay_in_pipe_at_first)
	
	match step:
		0:
			if up_or_down:
				step = 1
				Audio.play_sound(SOUND, self, false)
		1:
			position = position.move_toward(stretching_end, speed)
			if position == stretching_end:
				stretched_out.emit()
				step = 2
		2:
			if !up_or_down:
				step = 3
				Audio.play_sound(SOUND, self, false)
		3:
			position = position.move_toward(stretching_start, speed)
			if position == stretching_start:
				shrinked_in.emit()
				step = 0
