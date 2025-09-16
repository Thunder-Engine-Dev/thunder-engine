extends MenuSelection

@export var cancel_erase: bool = false

@onready var pause: Control = $"../.."

@onready var game_paused_2: TextureRect = $"../../GamePaused/GamePaused2"
@onready var progress_clearing: TextureRect = $"../../GamePaused/ProgressClearing"

@onready var progress_continue: Control = $"../.."
@onready var v_box_container_2: MenuItemsController = $"../../VBoxContainer2"

func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)

	if cancel_erase:
		var tw = create_tween().set_trans(Tween.TRANS_SINE).set_parallel()
		tw.tween_property(game_paused_2, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_IN)
		tw.tween_property(progress_clearing, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_OUT)
		v_box_container_2.focused = false
		progress_continue.v_box_container.visible = true
		v_box_container_2.visible = false
		for i in 2:
			await get_tree().physics_frame
			progress_continue.v_box_container.focused = true
			progress_continue.v_box_container.move_selector(2)
	else:
		pause.trigger_pipe()
		pause.toggle(false)
		pause.v_box_container.focused = false
