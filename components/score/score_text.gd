extends Label
class_name ScoreText

func _init(string: String, ref: Node2D):
	text = string
	
	label_settings = LabelSettings.new()
	label_settings.font = preload("res://engine/components/score/fonts/score.fnt")
	
	Scenes.current_scene.add_child(self)
	var pos = size / 2
	global_position = ref.global_position - pos
	# godot developers forgot to implement global_rotation in control nodes :skull:
	#global_rotation = Thunder._current_player.global_rotation
	
	var tw = get_tree().create_tween()
	tw.tween_property(self, "global_position:y", global_position.y - 48, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	var timer = get_tree().create_timer(2.5, false, true)
	timer.timeout.connect(disappear.bind(tw))

func disappear(tw):
	tw = get_tree().create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(queue_free)
