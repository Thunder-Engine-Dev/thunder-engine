extends "res://engine/objects/bumping_blocks/message_block/message_block.gd"

signal choice_accepted
signal choice_canceled


func _physics_process(delta: float) -> void:
	if !activated: return
	if !get_tree().paused:
		get_tree().paused = true
	if Input.is_action_just_pressed(&"ui_cancel"):
		hide_message()
		activated = false
		choice_canceled.emit()
		return
	if Input.is_action_just_pressed(&"ui_accept"):
		hide_message()
		activated = false
		choice_accepted.emit()
