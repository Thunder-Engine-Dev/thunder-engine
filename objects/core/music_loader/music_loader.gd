extends Node

@export var music: Array[Resource]
@export var index: int = 0:
	set(i):
		if index == i: return
		index = i
		_change_music(i, channel_id)

@export var channel_id: int = 1
@export var play_immediately: bool = true

var buffered_to_play: Array = []

func _ready() -> void:
	_change_music(index, channel_id)


func _change_music(index: int, ch_id: int) -> void:
	if music.size() <= index: return
	var options = [music[index], ch_id, { "ignore_pause": true }]
	if play_immediately:
		Audio.play_music(options[0], options[1], options[2])
	else:
		buffered_to_play = options
		print(buffered_to_play)


func _stop_music(channel_id: int) -> void:
	#buffered_to_play = []
	pass


func play_buffered() -> bool:
	if buffered_to_play.is_empty(): return false
	if buffered_to_play.size() < 3: return false
	Audio.play_music(buffered_to_play[0], buffered_to_play[1], buffered_to_play[2])
	buffered_to_play = []
	return true
