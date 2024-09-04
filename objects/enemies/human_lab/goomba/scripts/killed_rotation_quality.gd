extends Node2D

func _physics_process(delta: float) -> void:
	if !visible: return
	var quality: SettingsManager.QUALITY = SettingsManager.settings.quality
	if quality == SettingsManager.QUALITY.MIN:
		rotation += delta * 12.5
