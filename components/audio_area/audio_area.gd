extends Area2D

@export_category("Audio Area")
@export var audio_effects: Array[AudioEffect]
@export var keep_without_player: bool = true
@export_category("Keep only on these Quality Settings")
@export var maximum: bool = true
@export var medium: bool = true
@export var minimum: bool = false

@onready var quality: SettingsManager.QUALITY = SettingsManager.settings.quality
@onready var QUALITY = SettingsManager.QUALITY

var audio := AudioServer
var has_filter: bool

func _ready() -> void:
	SettingsManager.settings_updated.connect(_update_visibility)
	_update_visibility()
	body_entered.connect(_add_effect)
	body_exited.connect(_remove_effects)


func _update_visibility() -> void:
	var player = Thunder._current_player
	if is_shown() && !has_filter && get_overlapping_bodies().has(player):
		_add_effect(player)
		return
	if !is_shown() && has_filter && get_overlapping_bodies().has(player):
		_remove_effects(null)


func is_shown() -> bool:
	quality = SettingsManager.settings.quality
	var res: bool = (
		(maximum && quality == QUALITY.MAX) ||
		(medium && quality == QUALITY.MID) ||
		(minimum && quality == QUALITY.MIN)
	)
	return res


func _exit_tree() -> void:
	_remove_effects(null)


func _add_effect(player: Node2D) -> void:
	if !is_shown(): return
	if has_filter: return
	var p := Thunder._current_player
	if !p:
		print_debug("failed!")
		return
	
	var sound_channel := audio.get_bus_index(&"Sound")
	var sound_bus_effects: Array[AudioEffect] = []
	
	for i in audio.get_bus_effect_count(sound_channel):
		sound_bus_effects.append(i)
	for j in audio_effects:
		if j in sound_bus_effects:
			continue
		audio.add_bus_effect(sound_channel, j)
	has_filter = true

func _remove_effects(_p: Node2D = null) -> void:
	if keep_without_player && _p != null && Thunder._current_player && Thunder._current_player.is_dying:
		return
	var sound_channel := audio.get_bus_index(&"Sound")
	for i in audio.get_bus_effect_count(sound_channel):
		audio.remove_bus_effect(sound_channel, i)
	has_filter = false
