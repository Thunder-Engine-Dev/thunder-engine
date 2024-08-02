extends ScoreText
class_name ScoreTextLife

func _init(string: String, ref: Node2D, parent: Node = Scenes.current_scene):
	super(string, ref, parent)
	
	label_settings = LabelSettings.new()
	label_settings.font = preload("res://engine/components/score/fonts/life.fnt")
