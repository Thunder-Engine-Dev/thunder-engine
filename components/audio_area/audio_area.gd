extends Area2D

@export_category("Audio Area")
@export var audio_effects: Array[AudioEffect]

var audio := AudioServer


func _ready() -> void:
	body_entered.connect(_add_effect)
	body_exited.connect(_remove_effects)

func _exit_tree() -> void:
	_remove_effects(null)


func _add_effect(player: Node2D) -> void:
	var p := Thunder._current_player
	if !p:
		print("failed!")
		return
	
	var sound_channel := audio.get_bus_index(&"Sound")
	var sound_bus_effects: Array[AudioEffect] = []
	
	for i in audio.get_bus_effect_count(sound_channel):
		sound_bus_effects.append(i)
	for j in audio_effects:
		if j in sound_bus_effects:
			continue
		audio.add_bus_effect(sound_channel, j)

func _remove_effects(_p: Node2D = null) -> void:
	var sound_channel := audio.get_bus_index(&"Sound")
	for i in audio.get_bus_effect_count(sound_channel):
		audio.remove_bus_effect(sound_channel, i)
