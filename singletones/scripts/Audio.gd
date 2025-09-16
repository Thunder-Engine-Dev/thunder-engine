extends Node

## Singleton that manages musics and sounds for your game[br]
##
## We [b][i]extremely recommend[/i][/b] to use the methods in the singleton for playing your musics and sounds.[br]
## [b]Note:[/b] there are some methods with param [param other_keys]([Dictionary]), so here is the list of [i][u]spell_keys[/u][/i]:[br]
## ([float])[param pitch]: Determines the pitch of the sound or music
## ([float])[param volume]: Determines the volume of the sound or music (in dB)
## ([String])[param bus]: Determines which audio bus will the sound or music be attached to
## ([bool])[param ignore_pause]: Determines whether the sound or music should play when the SceneTree is paused

## Param set when you call [method fade_music_1d_player]
enum FadingMethod {
	LINEAR, ## Fading musics with [method @GlobalScope.move_toward]
	LERP, ## Fading musics with [method @GlobalScope.lerp]
	SMOOTH_STEP ## Fading musics with [method @GlobalScope.smoothstep] [i](Experimental!)[/i]
}

## Controlled by SettingsManager
var _settings_sound_bus_volume_db: float = 0:
	set(to):
		_settings_sound_bus_volume_db = to
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("1D Sound"), _target_sound_bus_volume_db + to)

## Controlled by SettingsManager
var _settings_music_bus_volume_db: float = 0:
	set(to):
		_settings_music_bus_volume_db = to
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _target_music_bus_volume_db + to)

## Set to overwrite sound bus volume, respecting user settings
var _target_sound_bus_volume_db: float = 0:
	set(to):
		_target_sound_bus_volume_db = to
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("1D Sound"), _settings_sound_bus_volume_db + to)

## Controlled by Pause
## Set to overwrite music bus volume, respecting user settings
var _target_music_bus_volume_db: float = 0:
	set(to):
		_target_music_bus_volume_db = to
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _settings_music_bus_volume_db + to)

var _music_channels: Dictionary = {}
var _music_tweens: Array[Tween]
var _duplicated_sounds: Array[AudioStream]

var _calculate_player_position = _lcpp.bind()

signal any_music_finished
signal music_started(channel_id: int)
signal music_stopped(channel_id: int, fading: bool)
signal all_musics_stopped()


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	Scenes.pre_scene_changed.connect(_stop_all_musics_scene_changed)


func _physics_process(delta):
	if !_duplicated_sounds.is_empty():
		_duplicated_sounds.clear()


func _lcpp(ref: Node2D) -> Vector2:
	return ref.global_position


func _create_2d_player(pos: Vector2, is_global: bool, is_permanent: bool = false) -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	if !is_permanent: player.finished.connect(player.queue_free)
	player.global_position = pos
	GlobalViewport.add_child.call_deferred(player)
	return player


func _create_1d_player(is_global: bool, is_permanent: bool = false) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	if !is_permanent: player.finished.connect(player.queue_free)
	if !is_global: Scenes.pre_scene_changed.connect(player.queue_free)
	add_child.call_deferred(player)
	return player


## Play a sound with given [AudioStream] resource and bind the sound player to a [Node2D][br]
## [b]Note:[/b] This method creates [AudioStreamPlayer2D] which plays sound with pan changed according to its position to the center of screen, rather than [AudioStreamPlayer].[br]
## [param resource] is the sound stream you are going to install[br]
## [param ref] is the node to be bound[br]
## [param is_global] determines whether the sound can be played only in certain scene or global, the ones playing in the scene will be cut when calling [method Scenes.switch_to_scene][br]
## [param other_keys] is a [Dictionary] to extend the playing method, please see the [i][u]spell_keys[/u][/i] above
func play_sound(resource: AudioStream, ref: Node2D, is_global: bool = true, other_keys: Dictionary = {}) -> void:
	# Stop on empty sound to avoid crashes
	if resource == null: return
	
	if _duplicated_sounds.has(resource): return
	_duplicated_sounds.append(resource)
	var player = _create_2d_player(_calculate_player_position.call(ref), is_global)
	player.bus = "Sound" if !(&"bus" in other_keys && other_keys.bus) else other_keys.bus
	player.stream = resource
	player.play.call_deferred()
	
	if &"pitch" in other_keys && (other_keys.pitch is float || other_keys.pitch is int):
		player.pitch_scale = other_keys.pitch
	if &"volume" in other_keys && (other_keys.volume is float || other_keys.volume is int):
		player.volume_db = other_keys.volume
	
	# Make the volume be on the same level as 1d sounds
	player.volume_db += 5
	player.process_mode = Node.PROCESS_MODE_ALWAYS \
		if &"ignore_pause" in other_keys && other_keys.ignore_pause \
		else Node.PROCESS_MODE_PAUSABLE


## Play a sound with given [AudioStream] resource[br]
## [b]Note:[/b] This method creates [AudioStreamPlayer], and please see [method play_sound] to learn their differences.[br]
## [param resource] is the sound stream you are going to install[br]
## [param ref] is the node to be bound[br]
## [param is_global] determines whether the sound can be played only in certain scene or global, the ones playing in the scene will be cut when calling [method Scenes.switch_to_scene][br]
## [param other_keys] is a [Dictionary] to extend the playing method, please see the [i][u]spell_keys[/u][i] above
func play_1d_sound(resource: AudioStream, is_global: bool = true, other_keys: Dictionary = {}) -> void:
	# Stop on empty sound to avoid crashes
	if resource == null: return
	
	if _duplicated_sounds.has(resource): return
	_duplicated_sounds.append(resource)
	var player = _create_1d_player(is_global)
	player.bus = "Sound" if !(&"bus" in other_keys && other_keys.bus) else other_keys.bus
	player.stream = resource
	player.play.call_deferred()
	
	if &"pitch" in other_keys && (other_keys.pitch is float || other_keys.pitch is int):
		player.pitch_scale = other_keys.pitch
	if &"volume" in other_keys && (other_keys.volume is float || other_keys.volume is int):
		player.volume_db = other_keys.volume
	player.process_mode = Node.PROCESS_MODE_ALWAYS \
		if &"ignore_pause" in other_keys && other_keys.ignore_pause \
		else Node.PROCESS_MODE_PAUSABLE


## Play a [b]music[/b] with given [AudioStream] resource and bind the sound player to a [Node2D].[br]
## [b]Note:[/b] Musics played are [b][u]GLOBAL[/u][/b]![br]
## [param resource] is the music stream you are going to install[br]
## [param channel_id] is the channel to play the music[br]
## [param other_keys] is a [Dictionary] to extend the playing method, please see the [i][u]spell_keys[/u][/i] above[br]
## [color=red][b]WARNING:[/b][/color] if you have played one and then played another one in the same channel, the latter one will [b]OVERRIDE[/b] the former one and restart playing!
## [codeblock]
## # First you played a music in a channel
## play_music(music,0)
## 
## # Then you played another music in the same channel
## play_music(music2,0)
##
## # The result would be: music2 is playing
## [/codeblock][br]
## So if you want to play musics in the same time without interferences, please make sure they are playing in different channels!
func play_music(resource: Resource, channel_id: int, other_keys: Dictionary = {}, is_global: bool = false, is_permanent: bool = true) -> AudioStreamPlayer:
	await get_tree().physics_frame
	if !resource: return null
	
	if !_music_channels.has(channel_id) || !is_instance_valid(_music_channels[channel_id]):
		_music_channels[channel_id] = _create_1d_player(is_global, is_permanent)
	var music_player = _music_channels[channel_id]
	
	music_player.finished.connect(func(): any_music_finished.emit(), CONNECT_ONE_SHOT)
	
	if ClassDB.get_parent_class(resource.get_class()) == &"AudioStream":
		music_player.stream = resource
		music_player.bus = &"Music" if !(&"bus" in other_keys && other_keys.bus) else other_keys.bus
		music_player.play.call_deferred()
	else:
		print("ERROR: Invalid data provided in method Audio.play_music")
		return null
	
	if &"pitch" in other_keys && (other_keys.pitch is float || other_keys.pitch is int):
		_music_channels[channel_id].pitch_scale = other_keys.pitch
	if &"volume" in other_keys && (other_keys.volume is float || other_keys.volume is int):
		_music_channels[channel_id].volume_db = other_keys.volume
	if &"fade_duration" in other_keys && (other_keys.fade_duration is float || other_keys.fade_duration is int):
		if &"fade_to" in other_keys && (other_keys.fade_to is float || other_keys.fade_to is int):
			var _fade_mtd = Tween.TransitionType.TRANS_LINEAR
			var _fade_ease = Tween.EaseType.EASE_IN
			if &"fade_method" in other_keys && other_keys.fade_method is Tween.TransitionType:
				_fade_mtd = other_keys.fade_method
			if &"fade_ease" in other_keys && other_keys.fade_ease is Tween.EaseType:
				_fade_ease = other_keys.fade_ease
			fade_music_1d_player(_music_channels[channel_id], other_keys.fade_to, other_keys.fade_duration, _fade_mtd, false, _fade_ease)
	_music_channels[channel_id].process_mode = Node.PROCESS_MODE_ALWAYS \
		if &"ignore_pause" in other_keys && other_keys.ignore_pause \
		else Node.PROCESS_MODE_PAUSABLE
	if &"start_from_sec" in other_keys && (other_keys.start_from_sec is float || other_keys.start_from_sec is int) && other_keys.start_from_sec > 0.0:
		_music_channels[channel_id].seek.call_deferred(other_keys.start_from_sec)
	music_started.emit(channel_id)
	
	return music_player if is_instance_valid(music_player) else null

## Fade a music player that is playing, and you can choose it's way to fade.[br]
## [param player] is the music player that is playing[br]
## [param to] is the final [member AudioStreamPlayer.volume_db] you wish[br]
## [param weight] is the strength/delta-value to fade the music[br]
## [param method] is the way to fade the music, different [param method] decides different [param weight] calculation. See [enum FadingMethod][br]
## [param stop_after_fading] determines whether the music stops playing after it fades to goal value. This is very useful when you are trying making fading-out-and-stop musics
func fade_music_1d_player(player: AudioStreamPlayer, to: float, duration: float, method: Tween.TransitionType = Tween.TRANS_LINEAR, stop_after_fading: bool = false, _ease: Tween.EaseType = Tween.EASE_IN) -> void:
	if !player: return
	if !is_instance_valid(player): return
	
	var tween: Tween = create_tween().set_trans(method).set_ease(_ease)
	tween.tween_property(player, "volume_db", to, duration)
	tween.tween_callback(
		func() -> void:
			if stop_after_fading && is_instance_valid(player):
				player.stop()
				player.free()
			tween.kill()
			if tween in _music_tweens:
				_music_tweens.erase(tween)
	)
	_music_tweens.append(tween)


## Stop a channel from playing
func stop_music_channel(channel_id: int, fade: bool) -> void:
	if !channel_id in _music_channels: return
	if !_music_channels[channel_id]: return
	if !fade:
		_music_channels[channel_id].stop()
	else:
		fade_music_1d_player(_music_channels[channel_id], -40, 2, Tween.TRANS_SINE, true)
	music_stopped.emit(channel_id, fade)


## Stop all musics from playing
func stop_all_musics(fade: bool = false) -> void:
	for i in _music_channels.keys():
		if !is_instance_valid(_music_channels[i]):
			continue
		if !fade:
			_music_channels[i].queue_free()
			_music_channels.erase(i)
		else:
			fade_music_1d_player(_music_channels[i], -40, 1.5, Tween.TRANS_LINEAR, true)
		music_stopped.emit(i, fade)
	all_musics_stopped.emit()

func _stop_all_musics_scene_changed() -> void:
	for i in _music_channels.keys():
		if !is_instance_valid(_music_channels[i]) || !_music_channels[i].get_meta(&"play_when_scene_changed", true):
			continue
		
		_music_channels[i].queue_free()
		_music_channels.erase(i)
		music_stopped.emit(i, false)
	all_musics_stopped.emit()


func stop_all_sounds() -> void:
	for i in GlobalViewport.get_children():
		if i is AudioStreamPlayer2D || i is AudioStreamPlayer:
			i.stop()
			i.queue_free()
