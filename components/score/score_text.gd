extends Label
class_name ScoreText

func _init(string: String, ref: Node2D, parent: Node = Scenes.current_scene, accept_zero: bool = false):
	if !accept_zero && string == "0":
		queue_free()
		return
	text = string
	
	label_settings = LabelSettings.new()
	label_settings.font = preload("res://engine/components/score/fonts/score.fnt")
	var _is_negative: bool = text.begins_with("-")
	if _is_negative:
		label_settings.font_color = Color(1.0, 0.314, 0.314)
	
	parent.add_child(self)
	global_position = ref.global_position - (size / 2)
	z_index = 1000
	
	var tw = get_tree().create_tween()
	tw.tween_property(
		self,
		"global_position:y",
		global_position.y - 48 + (96 * int(_is_negative)),
		1.0
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(2.5)
	tw.tween_property(self, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(queue_free)
