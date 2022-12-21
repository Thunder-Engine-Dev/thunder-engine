extends VisibleOnScreenNotifier2D

@export_category("VisionDetector")
@export_node_path(Node2D) var target_nodepath:NodePath = ^".."
@export var disabled_when_out_of_screen: bool
@export var active_once: bool = true

var activated: bool
var source_process_mode: int = PROCESS_MODE_INHERIT

@onready var target_node:Node2D = get_node_or_null(target_nodepath)


func _ready() -> void:
	var set_mode_on: Callable = func() -> void:
		if target_node:
			target_node.process_mode = source_process_mode
			source_process_mode = PROCESS_MODE_INHERIT
	var set_mode_off: Callable = func() -> void:
		if target_node:
			source_process_mode = target_node.process_mode
			target_node.process_mode = PROCESS_MODE_DISABLED
	
	if disabled_when_out_of_screen:
		set_mode_off.call()
	
	screen_entered.connect(
		func() -> void:
			if !activated:
				if target_node && disabled_when_out_of_screen:
					set_mode_on.call()
				if active_once:
					activated = true
	)
	
	screen_exited.connect(
		func() -> void:
			if !activated:
				if target_node && disabled_when_out_of_screen:
					set_mode_off.call()
	)
