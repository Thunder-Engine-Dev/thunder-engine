extends Node2D

@export var stay_in_pipe_at_first: bool = true
@export var range_in_pipe: float = 80.0
@export var stay_in_interval: float = 1.0
@export var stay_out_interval: float = 1.0
@export var stretching_speed: float = 50.0
@export var stretching_length: float = 60.0
@export var custom_vars: Dictionary
@export var custom_script: Script

var step: int
var first_visible: bool = false

@onready var vision: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var timer_step: Timer = $Step
@onready var light: PointLight2D = get_node_or_null(^"PointLight2D") as PointLight2D
@onready var light_energy: float = light.energy if light else 0.0
@onready var extra_script: Script = ByNodeScript.activate_script(custom_script, self, custom_vars)

@onready var stretching_end: Vector2 = position
@onready var stretching_start: Vector2 = stretching_end + (Vector2.DOWN * stretching_length).rotated(rotation)

signal shrinked_in
signal stretched_out


func _ready() -> void:
	if stay_in_pipe_at_first:
		position = stretching_start
		reset_physics_interpolation()
	else: step = 3
	
	_update_light()
	
	timer_step.timeout.connect(
		func() -> void:
			step += 1
			if step >= 4: step = 0
	)

func _process(_delta: float) -> void:
	_update_light()


func _update_light() -> void:
	if !light: return
	var total: float = stretching_start.distance_to(stretching_end)
	var out: float = 1.0 if is_zero_approx(total) else 1.0 - position.distance_to(stretching_end) / total
	light.energy = light_energy * smoothstep(1.0 / 3.0, 2.0 / 3.0, out)


func _physics_process(delta: float) -> void:
	var speed: float = stretching_speed * delta
	var player: Node2D = Thunder._current_player
	var ppos: Vector2 = global_transform.affine_inverse().basis_xform(player.global_position if player else Vector2.ZERO)
	var spos: Vector2 = global_transform.affine_inverse().basis_xform(global_position)
	var can_stretch_out: bool = vision.is_on_screen() && player && abs(spos.x - ppos.x) > range_in_pipe
	if !first_visible:
		first_visible = vision.is_on_screen()
	if !first_visible:
		return
	
	match step:
		0:
			if can_stretch_out:
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
