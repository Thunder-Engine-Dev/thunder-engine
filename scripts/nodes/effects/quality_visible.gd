extends Node2D

@export_category("Keep only on these Quality Settings")
@export var maximum: bool = true
@export var medium: bool = false
@export var minimum: bool = false

@onready var quality: SettingsManager.QUALITY = SettingsManager.settings.quality
@onready var QUALITY = SettingsManager.QUALITY

func _ready() -> void:
	SettingsManager.settings_updated.connect(_update_visibility)
	_update_visibility()


func _update_visibility() -> void:
	quality = SettingsManager.settings.quality
	visible = (
		(maximum && quality == QUALITY.MAX) ||
		(medium && quality == QUALITY.MED) ||
		(minimum && quality == QUALITY.MIN)
	)
	
