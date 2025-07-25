@tool
@icon("./icon.svg")
extends Node2D
class_name Stage2D

## Base stage/scene class[br]
## When the instance of the class gets notified with [member Node._ready], the instance
## will automatically call [method Scenes.register] to make [member Scenes.current_scene] work decently

@export_group("Lighting", "lighting_")
## Hides [Light2D] nodes in scenes that have blend mode set to "Mix" (affects scenes like Fireball, Powerups, etc).
## Such lights are visually invisible in regular bright levels, but despite that fact, they're still rendered.
## For performance reasons, they're off by default.[br][br]
## Only set this to [code]false[/code] when you work with dark levels and/or areas ([CanvasModulate] node).[br]
## You can also toggle this at runtime using [method Stage2D.disable_object_lighting]
## and [method Stage2D.enable_object_lighting].[br][br]
## Note that such [Light2D] nodes must have a corresponding script attached for this option to affect them.
@export var lighting_force_hide_on_start: bool = true
## Configures whether lights described above should appear on different quality levels (via an in-game option).[br][br]
## If you have a dark area and you do not handle Minimum quality, it's adviced to turn it on.[br][br]
## See [param Stage2D.lighting_force_hide_on_start] for more information.
@export_flags("Minimum:1", "Medium:2", "Maximum:4") var lighting_show_on_quality = 6
## If [code]true[/code], the pause menu cannot be opened.
@export var disable_pause_menu: bool = false

var _is_stage_ready: bool
var is_lighting_visible: bool = !lighting_force_hide_on_start
signal stage_ready


func _ready() -> void:
	SettingsManager.settings_updated.connect(_update_lighting_visibility)
	_update_lighting_visibility.call_deferred()
	await get_tree().physics_frame
	while get_tree().is_paused():
		await get_tree().physics_frame
	for i in 5:
		await get_tree().physics_frame
	_is_stage_ready = true
	stage_ready.emit()


## Fast method to call [method Scenes.reload_current_scene] in [Stage2D] and its extended classes
func restart() -> void:
	Scenes.reload_current_scene()


func disable_object_lighting() -> void:
	lighting_force_hide_on_start = true
	_update_lighting_visibility()

func enable_object_lighting() -> void:
	lighting_force_hide_on_start = false
	_update_lighting_visibility()

func _update_lighting_visibility() -> void:
	var quality = SettingsManager.settings.quality
	var _lighting_quality: bool = (
		(lighting_show_on_quality & 4 && quality == SettingsManager.QUALITY.MAX) ||
		(lighting_show_on_quality & 2 && quality == SettingsManager.QUALITY.MID) ||
		(lighting_show_on_quality & 1 && quality == SettingsManager.QUALITY.MIN)
	)
	if _lighting_quality && !lighting_force_hide_on_start:
		is_lighting_visible = true
		get_tree().call_group(&"stage2d_ctrl_light", &"show")
	else:
		is_lighting_visible = false
		get_tree().call_group(&"stage2d_ctrl_light", &"hide")
