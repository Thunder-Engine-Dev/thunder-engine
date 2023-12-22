extends Node

@export var music: Array[Resource]
@export var index: int = 0:
	set(i):
		if index == i: return
		index = i
		_change_music(i, channel_id)

@export var channel_id: int = 1
@export var play_immediately: bool = true

var buffer: Array = []
var is_paused: bool = false

func _ready() -> void:
	_change_music(index, channel_id)


func _change_music(ind: int, ch_id: int) -> void:
	if music.size() <= ind: return
	var options = [music[index], ch_id, { "ignore_pause": true }]
	if play_immediately:
		Audio.play_music(options[0], options[1], options[2])
		is_paused = false
	else:
		buffer = options


func pause_music(ind: int = index, ch_id: int = channel_id) -> void:
	if !Audio._music_channels.has(ch_id) || !is_instance_valid(Audio._music_channels[ch_id]):
		return
	var music_player = Audio._music_channels[ch_id]
	music_player.playing = false
	if Audio._music_channels[ch_id].has_meta(&"openmpt"):
		Audio._music_channels[ch_id].get_meta(&"openmpt").stop()
	is_paused = true


func unpause_music(ind: int = index, ch_id: int = channel_id) -> void:
	if !Audio._music_channels.has(ch_id) || !is_instance_valid(Audio._music_channels[ch_id]):
		return
	var music_player = Audio._music_channels[ch_id]
	music_player.playing = true
	if Audio._music_channels[ch_id].has_meta(&"openmpt"):
		Audio._music_channels[ch_id].get_meta(&"openmpt").start(false)
	is_paused = false


func play_buffered(buffered_to_play: Array = buffer) -> bool:
	if buffered_to_play.is_empty(): return false
	if buffered_to_play.size() < 3: return false
	if is_paused:
		Audio.stop_all_musics()
	Audio.play_music(buffered_to_play[0], buffered_to_play[1], buffered_to_play[2])
	buffered_to_play = []
	is_paused = false
	return true
