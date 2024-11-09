extends Node2D

func _physics_process(delta: float) -> void:
	if !visible: return
	if SettingsManager.get_quality() == SettingsManager.QUALITY.MIN:
		rotation += delta * 12.5
