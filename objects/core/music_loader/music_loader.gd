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
@export var can_pause: bool = false
@export var volume_db: Array[float]
@export var start_from_sec: Array[float]
## If [code]true[/code] for a track, its pitch/speed follows [member Engine.time_scale]
## so the music stays in sync with game speed.
@export var sync_with_time_scale: Array[bool]
## Module subsong index. Module format only (MPT). Set to -1 for default.
@export var subsong: Array[int]
@export_group(&"Custom Script")
@export var custom_vars: Dictionary
@export var custom_script: GDScript

@onready var extra_script: Script = ByNodeScript.activate_script(custom_script, self, custom_vars)

var buffer: Array = []
var is_paused: bool = false

var _crossfade: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)
var _sync_time_scale: bool = false
var _synced_player: AudioStreamPlayer
var _synced_stream: AudioStream


func _ready() -> void:
	_init_array(volume_db)
	_init_array(start_from_sec)
	_init_array(subsong)
	if sync_with_time_scale.size() < music.size():
		sync_with_time_scale.resize(music.size())
	set_process(false)
	Audio.music_started.connect(_on_audio_music_started)
	Audio.music_stopped.connect(_on_audio_music_stopped)
	
	# Named method (not a capturing lambda): scene changes can free this node
	# before idle, and deferred lambdas then hit "Bad address index"
	_sync_global_music_connection.call_deferred()
	
	if play_globally == GLOBAL_TYPE.CHECK_FOR_ONETIME_BLOCKS && !Data.values.onetime_blocks:
		return
	
	if stop_all_music_on_start:
		Audio.stop_all_musics()
	
	_change_music(index, channel_id)


func _init_array(arr: Array) -> void:
	if arr.size() < music.size():
		arr.resize(music.size())
	for i in arr.size():
		if arr[i] == null: 
			arr[i] = 0.0


func _change_music(ind: int, ch_id: int) -> void:
	if music.size() <= ind: return
	var options = [
		music[ind], 
		ch_id, 
		{
			&"ignore_pause": !can_pause, 
			&"volume": volume_db[ind] if volume_db.size() > ind else 0.0,
			&"start_from_sec": start_from_sec[ind] if start_from_sec.size() > ind else 0.0,
			&"subsong": subsong[ind] if subsong.size() > ind else 0,
		}
	]
	if play_immediately:
		music_started.emit(ind)
		var _trans = TransitionManager.current_transition
		if _crossfade && is_instance_valid(_trans) && _trans.name == "crossfade_transition":
			await _trans.end
			if !is_inside_tree():
				return
		var player = await Audio.play_music(options[0], options[1], options[2], play_globally)
		if !is_inside_tree():
			return
		# Pass player as an argument. A lambda capturing it after await lives on
		# the coroutine stack and crashes with "Bad address index" if this node
		# is freed during a fast scene switch.
		_apply_global_music_meta.call_deferred(player)
		_begin_time_scale_sync(ind, player)
		is_paused = false
	else:
		music_buffered.emit(ind)
		buffer = options


func _sync_global_music_connection() -> void:
	if play_globally && Scenes.pre_scene_changed.is_connected(Audio._stop_all_musics_scene_changed):
		Scenes.pre_scene_changed.disconnect(Audio._stop_all_musics_scene_changed)
	if !play_globally && !Scenes.pre_scene_changed.is_connected(Audio._stop_all_musics_scene_changed):
		Scenes.pre_scene_changed.connect(Audio._stop_all_musics_scene_changed)


func _apply_global_music_meta(player: AudioStreamPlayer) -> void:
	if play_globally && is_instance_valid(player):
		player.set_meta(&"play_when_scene_changed", true)


func pause_music(ind: int = index, ch_id: int = channel_id) -> void:
	if !Audio._music_channels.has(ch_id) || !is_instance_valid(Audio._music_channels[ch_id]):
		return
	var music_player = Audio._music_channels[ch_id]
	if music_player.process_mode != Node.ProcessMode.PROCESS_MODE_DISABLED:
		music_player.set_meta("old_process_mode", music_player.process_mode)
	music_player.process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED
	is_paused = true
	music_paused.emit()


func unpause_music(ind: int = index, ch_id: int = channel_id) -> void:
	if !Audio._music_channels.has(ch_id) || !is_instance_valid(Audio._music_channels[ch_id]):
		return
	var music_player = Audio._music_channels[ch_id]
	index = ind
	music_player.process_mode = music_player.get_meta("old_process_mode", 3)
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
	var _trans = TransitionManager.current_transition
	if _crossfade && is_instance_valid(_trans) && _trans.name == "crossfade_transition":
		await _trans.end
		if !is_inside_tree():
			return false
	var player = await Audio.play_music(buffered_to_play[0], buffered_to_play[1], buffered_to_play[2], play_globally)
	if !is_inside_tree():
		return false
	music_resumed_buffered.emit()
	_begin_time_scale_sync(index, player)
	buffered_to_play = []
	is_paused = false
	return true

func set_index(ind: int) -> void:
	index = ind


func _exit_tree() -> void:
	if Audio.music_started.is_connected(_on_audio_music_started):
		Audio.music_started.disconnect(_on_audio_music_started)
	if Audio.music_stopped.is_connected(_on_audio_music_stopped):
		Audio.music_stopped.disconnect(_on_audio_music_stopped)


func _is_time_scale_sync(ind: int) -> bool:
	return ind >= 0 && sync_with_time_scale.size() > ind && sync_with_time_scale[ind]


func _begin_time_scale_sync(ind: int, player: AudioStreamPlayer = null) -> void:
	_stop_time_scale_sync()
	if !_is_time_scale_sync(ind) || !is_instance_valid(player):
		return
	_sync_time_scale = true
	_synced_player = player
	_synced_stream = player.stream
	set_process(true)
	_apply_time_scale_pitch()


func _stop_time_scale_sync() -> void:
	_sync_time_scale = false
	_synced_player = null
	_synced_stream = null
	set_process(false)


func _on_audio_music_started(ch_id: int) -> void:
	if !_sync_time_scale || ch_id != channel_id:
		return
	if !_is_synced_player_current():
		_stop_time_scale_sync()


func _on_audio_music_stopped(ch_id: int, _fading: bool) -> void:
	if !_sync_time_scale || ch_id != channel_id:
		return
	_stop_time_scale_sync()


func _is_synced_player_current() -> bool:
	if !is_instance_valid(_synced_player):
		return false
	if Audio._music_channels.get(channel_id) != _synced_player:
		return false
	if _synced_player.stream != _synced_stream:
		return false
	return true


func _apply_time_scale_pitch() -> void:
	if !_sync_time_scale:
		return
	if !_is_synced_player_current():
		_stop_time_scale_sync()
		return
	var ts: float = maxf(Engine.time_scale, 0.001)
	# OpenMPT playback treats AudioStreamPlayer.pitch_scale inverted.
	if _synced_player.stream is AudioStreamMPT:
		_synced_player.pitch_scale = 1.0 / ts
	else:
		_synced_player.pitch_scale = ts


func _process(_delta: float) -> void:
	if !_sync_time_scale:
		set_process(false)
		return
	_apply_time_scale_pitch()
