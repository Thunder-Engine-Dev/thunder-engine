extends MenuSelection

@export var really_erase: bool = false

@onready var game_paused_2: TextureRect = $"../../GamePaused/GamePaused2"
@onready var progress_clearing: TextureRect = $"../../GamePaused/ProgressClearing"

@onready var progress_continue: Control = $"../.."
@onready var v_box_container_2: MenuItemsController = $"../../VBoxContainer2"

func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)
	
	if really_erase:
		ProfileManager.delete_profile("suspended")
		Audio.play_1d_sound(preload("res://engine/objects/bumping_blocks/_sounds/break.wav"))
		progress_continue.toggle(false)
		v_box_container_2.focused = false
		progress_continue.trigger_pipe()
	else:
		var tw = create_tween().set_trans(Tween.TRANS_SINE).set_parallel()
		tw.tween_property(progress_clearing, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_IN)
		tw.tween_property(game_paused_2, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_OUT)
		progress_continue.v_box_container.focused = false
		progress_continue.v_box_container.visible = false
		v_box_container_2.visible = true
		for i in 2:
			await get_tree().physics_frame
			v_box_container_2.focused = true
			v_box_container_2.move_selector(0)
	
