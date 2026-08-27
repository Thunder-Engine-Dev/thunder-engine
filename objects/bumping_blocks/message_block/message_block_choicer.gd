extends "res://engine/objects/bumping_blocks/message_block/message_block.gd"

signal choice_accepted
signal choice_canceled

@onready var text_2: CanvasItem = $CanvasLayer/Box/Texture/Text2


func _ready() -> void:
	if text_2:
		text_2.modulate.a = 0
		var tw := text_2.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		tw.tween_property(text_2, ^"modulate:a", 1, 0.5)
		tw.tween_property(text_2, ^"modulate:a", 0.2, 0.5)


func _physics_process(_delta: float) -> void:
	if !activated:
		return
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
