extends Node

signal music_started(music_id: int)
signal music_paused
signal music_unpaused
signal music_buffered(music_id: int)
signal music_resumed_buffered()

enum GLOBAL_TYPE {
	NO,
	CHECK_FOR_ONETIME_BLOCKS,
	ALWAYS_PLAY_GLOBALLY
}

@export var music: Array[Resource]
@export var index: int = 0:
	set(i):
		if index == i: return
		index = i
		_change_music(i, channel_id)

@export var channel_id: int = 1
@export var play_immediately: bool = true
@export var stop_all_music_on_start: bool = true
@export var play_globally: GLOBAL_TYPE = GLOBAL_TYPE.NO
@export var volume_db: Array[float]
@export_group(&"Custom Script")
@export var custom_vars: Dictionary
@export var custom_script: GDScript

@onready var extra_script: Script = ByNodeScript.activate_script(custom_script, self, custom_vars)

var buffer: Array = []
var is_paused: bool = false


func _ready() -> void:
	if volume_db.size() < music.size():
		volume_db.resize(music.size())
	for i in volume_db.size():
		if volume_db[i] == null: 
			volume_db[i] = 0
	
	(func() -> void:
		if play_globally && Scenes.pre_scene_changed.is_connected(Audio._stop_all_musics_scene_changed):
			Scenes.pre_scene_changed.disconnect(Audio._stop_all_musics_scene_changed)
		if !play_globally && !Scenes.pre_scene_changed.is_connected(Audio._stop_all_musics_scene_changed):
			Scenes.pre_scene_changed.connect(Audio._stop_all_musics_scene_changed)
	).call_deferred() # To ensure the connection/disconnection is successful
	
	if play_globally == GLOBAL_TYPE.CHECK_FOR_ONETIME_BLOCKS && !Data.values.onetime_blocks:
		return
	
	if stop_all_music_on_start:
		Audio.stop_all_musics()
	
	_change_music(index, channel_id)


func _change_music(ind: int, ch_id: int) -> void:
	if music.size() <= ind: return
	var options = [
		music[ind], 
		ch_id, 
		{
			"ignore_pause": true, 
			"volume": volume_db[ind] if volume_db.size() >= ind else 0.0
		}
	]
	if play_immediately:
		music_started.emit(ind)
		var player = await Audio.play_music(options[0], options[1], options[2], play_globally)
		(func():
			if play_globally && player:
				player.set_meta(&"play_when_scene_changed", true)
		).call_deferred()
		is_paused = false
	else:
		music_buffered.emit(ind)
		buffer = options


func pause_music(ind: int = index, ch_id: int = channel_id) -> void:
	if !Audio._music_channels.has(ch_id) || !is_instance_valid(Audio._music_channels[ch_id]):
		return
	var music_player = Audio._music_channels[ch_id]
	music_player.playing = false
	if music_player.has_meta(&"openmpt"):
		Audio._music_channels[ch_id].get_meta(&"openmpt").stop()
	is_paused = true
	music_paused.emit()


func unpause_music(ind: int = index, ch_id: int = channel_id) -> void:
	if !Audio._music_channels.has(ch_id) || !is_instance_valid(Audio._music_channels[ch_id]):
		return
	var music_player = Audio._music_channels[ch_id]
	index = ind
	music_player.play()
	if music_player.has_meta(&"openmpt"):
		var openmpt: OpenMPT = Audio._music_channels[ch_id].get_meta(&"openmpt")
		(func() -> void:
			music_player.play()
			openmpt.set_audio_generator_playback(music_player)
			openmpt.start(true)
		).call_deferred()
	is_paused = false
	music_unpaused.emit()


func play_or_buffer(ind: int = index, ch_id: int = channel_id) -> void:
	if !Audio._music_channels.has(ch_id) || !is_instance_valid(Audio._music_channels[ch_id]):
		return
	if !buffer.is_empty():
		buffer[0] = music[ind]
		buffer[1] = ch_id
	
	index = ind
	

func play_buffered(buffered_to_play: Array = buffer) -> bool:
	if buffered_to_play.is_empty(): return false
	if buffered_to_play.size() < 3: return false
	if is_paused:
		Audio.stop_all_musics()
	Audio.play_music(buffered_to_play[0], buffered_to_play[1], buffered_to_play[2], play_globally)
	music_resumed_buffered.emit()
	buffered_to_play = []
	is_paused = false
	return true
