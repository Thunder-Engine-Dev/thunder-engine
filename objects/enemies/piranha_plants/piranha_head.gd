extends Node2D

@export var fire_interval: float = 0.0

@export var custom_vars: Dictionary
@export var custom_script: Script

@onready var vision: VisibleOnScreenNotifier2D = $Vision
@onready var timer_step: Timer = get_node_or_null(^"Step")
@onready var extra_script: Script = ByNodeScript.activate_script(custom_script, self, custom_vars)

var step: int
var first_visible: bool = false

signal shrinked_in
signal stretched_out

func _ready() -> void:
	if !is_instance_valid(timer_step):
		assert(fire_interval <= 0.0, "Timer node named 'Step' is needed to function properly")
		return
	timer_step.timeout.connect(
		func() -> void:
			step += 1
			if step >= 4: step = 0
	)

func _physics_process(delta):
	if fire_interval <= 0.0: return
	var can_stretch_out: bool = vision.is_on_screen()
	if !first_visible:
		first_visible = can_stretch_out
	if !first_visible:
		return
	match step:
		0:
			if can_stretch_out:
				step = 1
		1:
			stretched_out.emit()
			step = 2
			timer_step.start(fire_interval)
		3:
			shrinked_in.emit()
			step = 0
