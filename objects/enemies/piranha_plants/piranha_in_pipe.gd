extends Node2D

@export var stay_in_pipe_at_first: bool = true
@export var range_in_pipe: float = 70.0
@export var stay_in_interval: float = 0.83
@export var stay_out_interval: float = 0.83
@export var stretching_speed: float = 50.0
@export var stretching_length: float = 64.0
@export var custom_vars:Dictionary
@export var custom_script:Script

var step: int

@onready var vision:VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var timer_step:Timer = $Step
@onready var extra_script:Script = ByNodeScript.activate_script(custom_script, self, custom_vars)

@onready var stretching_end: Vector2 = position
@onready var stretching_start: Vector2 = stretching_end + (Vector2.DOWN * stretching_length).rotated(rotation)

signal shrinked_in
signal stretched_out


func _ready() -> void:
	if stay_in_pipe_at_first: position = stretching_start
	else: step = 3
	
	timer_step.timeout.connect(
		func() -> void:
			step += 1
			if step >= 4: step = 0
	)

func _physics_process(delta: float) -> void:
	var speed: float = stretching_speed * delta
	var player: Node2D = Thunder._current_player
	var ppos: Vector2 = global_transform.affine_inverse().basis_xform(player.global_position)
	var spos: Vector2 = global_transform.affine_inverse().basis_xform(global_position)
	var can_strech_out: bool = !vision.is_on_screen() && player && abs(spos.x - ppos.x) > range_in_pipe
	
	match step:
		0:
			if can_strech_out:
				step = 1
		1:
			position = position.move_toward(stretching_end, speed)
			if position == stretching_end:
				stretched_out.emit()
				step = 2
				timer_step.start(stay_out_interval)
		3:
			position = position.move_toward(stretching_start, speed)
			if position == stretching_start:
				shrinked_in.emit()
				step = 4
				timer_step.start(stay_in_interval)
