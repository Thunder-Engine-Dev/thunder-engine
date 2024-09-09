extends Control

var opened: bool
var open_blocked: bool

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var v_box_container: MenuItemsController = $VBoxContainer

signal popped
signal closed

func _ready() -> void:
	animation_player.play(&"init")
	show()


func toggle(no_resume: bool = false, no_sound_effect: bool = false) -> void:
	#if !v_box_container.focused && opened: return
	
	if !opened && is_instance_valid(TransitionManager.current_transition):
		return
	
	if open_blocked: return
	
	opened = !opened
	if opened:
		popped.emit()
	else:
		closed.emit()
	
	$'..'.offset = Vector2.ZERO
	
	if opened:
		v_box_container.move_selector(0, true)
		animation_player.play("open")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		animation_player.play_backwards("open")
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	for i in 2:
		await get_tree().physics_frame
	
	v_box_container.focused = opened
	#options.focused = false
	#controls_options.focused = false
