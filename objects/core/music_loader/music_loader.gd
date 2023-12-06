extends Node

@export var music: Array[Resource]
@export var index: int = 0:
	set(i):
		if index == i: return
		index = i
		_change_music(i, channel_id)

@export var channel_id: int = 1

func _ready() -> void:
	_change_music(index, channel_id)


func _change_music(index: int, channel_id: int) -> void:
	if music.size() <= index: return
	Audio.play_music(music[index], channel_id, { "ignore_pause": true })


func _stop_music(channel_id: int) -> void:
	pass
