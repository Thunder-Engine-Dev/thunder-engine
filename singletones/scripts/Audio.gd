extends Node

## Singleton that manages musics and sounds for your game[br]
##
## We [b][i]extremely recommend[/i][/b] to use the methods in the singleton for playing your musics and sounds.[br]
## [b]Note:[/b] there are some methods with param [param other_keys]([Dictionary]), so here is the list of [i][u]spell_keys[/u][/i]:[br]
## ([float])[param pitch]: Determines the pitch of the sound or music

## Param set when you call [method fade_music_1d_player]
enum FadingMethod {
	LINEAR, ## Fading musics with [method @GlobalScope.move_toward]
	LERP, ## Fading musics with [method @GlobalScope.lerp]
	SMOOTH_STEP ## Fading musics with [method @GlobalScope.smoothstep] [i](Experimental!)[/i]
}

var _music_channels: Dictionary = {}
var _music_tweens: Array[Tween]
var _duplicated_sounds: Array[AudioStream]

var _calculate_player_position = _lcpp.bind()

signal any_music_finished


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


func _create_openmpt_player(is_global: bool) -> OpenMPT:
	var openmpt = OpenMPT.new()
	if !is_global: Scenes.pre_scene_changed.connect(openmpt.queue_free)
	add_child(openmpt)
	openmpt.stop()
	return openmpt


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
	player.bus = "Sound"
	player.stream = resource
	player.play.call_deferred()
	
	if &"pitch" in other_keys && other_keys.pitch is float:
		player.pitch_scale = other_keys.pitch
	if &"volume" in other_keys && other_keys.volume is float:
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
	player.bus = "Sound"
	player.stream = resource
	player.play.call_deferred()
	
	if &"pitch" in other_keys && other_keys.pitch is float:
		player.pitch_scale = other_keys.pitch
	if &"volume" in other_keys && other_keys.volume is float:
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
	await get_tree().process_frame
	if !resource: return null
	
	if !_music_channels.has(channel_id) || !is_instance_valid(_music_channels[channel_id]):
		_music_channels[channel_id] = _create_1d_player(is_global, is_permanent)
	var music_player = _music_channels[channel_id]
	
	music_player.finished.connect(func(): any_music_finished.emit(), CONNECT_ONE_SHOT)
	
	var openmpt: OpenMPT = null
	
	if ClassDB.get_parent_class(resource.get_class()) == &"AudioStream":
		music_player.stream = resource
		music_player.bus = &"Music"
		music_player.play.call_deferred()
	elif &"data" in resource:
		openmpt = _create_openmpt_player(is_global)
		if !openmpt:
			return null
		
		openmpt.load_module_data(resource.data)
		if !openmpt.is_module_loaded():
			printerr("[Audio] Failed to load file using tracker loader")
			openmpt.queue_free()
			music_player.queue_free()
			return null
		music_player.set_meta(&"openmpt", openmpt)
		
		var generator = AudioStreamGenerator.new()
		generator.buffer_length = 0.04
		generator.mix_rate = 44100
		
		music_player.stream = generator
		music_player.bus = &"Music"
		(func() -> void:
			music_player.play()
			#music_player.seek(0.0)
			openmpt.set_audio_generator_playback(music_player)
			openmpt.set_render_interpolation(resource.interpolation)
			openmpt.set_repeat_count(0 if !resource.loop else -1)
			#_music_channels[channel_id].volume_db = resource.volume_offset
			openmpt.start(true)
			#openmpt.set_position_seconds(0.0)
		).call_deferred()
	else:
		printerr("Invalid data provided in method Audio.play_music")
		return null
	
	if &"pitch" in other_keys && other_keys.pitch is float:
		_music_channels[channel_id].pitch_scale = other_keys.pitch
	if &"volume" in other_keys && other_keys.volume is float:
		_music_channels[channel_id].volume_db = other_keys.volume
	if &"fade_duration" in other_keys && other_keys.fade_duration is float:
		if &"fade_to" in other_keys && other_keys.fade_to is float:
			fade_music_1d_player(_music_channels[channel_id], other_keys.fade_to, other_keys.fade_duration)
	_music_channels[channel_id].process_mode = Node.PROCESS_MODE_ALWAYS \
		if &"ignore_pause" in other_keys && other_keys.ignore_pause \
		else Node.PROCESS_MODE_PAUSABLE
	if &"start_from_sec" in other_keys && other_keys.start_from_sec is float && other_keys.start_from_sec > 0.0:
		if openmpt:
			openmpt.set_position_seconds.call_deferred(other_keys.start_from_sec)
		else:
			_music_channels[channel_id].seek.call_deferred(other_keys.start_from_sec)
	
	return music_player if is_instance_valid(music_player) else null

## Fade a music player that is playing, and you can choose it's way to fade.[br]
## [param player] is the music player that is playing[br]
## [param to] is the final [member AudioStreamPlayer.volume_db] you wish[br]
## [param weight] is the strength/delta-value to fade the music[br]
## [param method] is the way to fade the music, different [param method] decides different [param weight] calculation. See [enum FadingMethod][br]
## [param stop_after_fading] determines whether the music stops playing after it fades to goal value. This is very useful when you are trying making fading-out-and-stop musics
func fade_music_1d_player(player: AudioStreamPlayer, to: float, duration: float, method: Tween.TransitionType = Tween.TRANS_LINEAR, stop_after_fading: bool = false, ease: Tween.EaseType = Tween.EASE_IN) -> void:
	if !player: return
	if !is_instance_valid(player): return
	
	var tween: Tween = create_tween().set_trans(method).set_ease(ease)
	tween.tween_property(player, "volume_db", to, duration)
	tween.tween_callback(
		func() -> void:
			if stop_after_fading && is_instance_valid(player):
				player.stop()
				if player.has_meta("openmpt"):
					var openmpt = player.get_meta("openmpt")
					if is_instance_valid(openmpt):
						openmpt.queue_free()
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
		if _music_channels[channel_id].has_meta("openmpt"):
			var openmpt = _music_channels[channel_id].get_meta("openmpt")
			if is_instance_valid(openmpt):
				openmpt.queue_free()
	else:
		fade_music_1d_player(_music_channels[channel_id], -40, 2, Tween.TRANS_SINE, true)


## Stop all musics from playing
func stop_all_musics(fade: bool = false) -> void:
	for i in _music_channels:
		if !is_instance_valid(_music_channels[i]):
			continue
		if !fade:
			if _music_channels[i].has_meta("openmpt"):
				var openmpt = _music_channels[i].get_meta("openmpt")
				if is_instance_valid(openmpt):
					openmpt.queue_free()
			if &"OpenMPT" in _music_channels[i].name:
				i.queue_free()
			
			_music_channels[i].queue_free()
			_music_channels.erase(i)
		else:
			fade_music_1d_player(_music_channels[i], -40, 1.5, Tween.TRANS_LINEAR, true)

func _stop_all_musics_scene_changed() -> void:
	for i in _music_channels:
		if !is_instance_valid(_music_channels[i]) || !_music_channels[i].get_meta(&"play_when_scene_changed", true):
			continue
		if _music_channels[i].has_meta("openmpt"):
			var openmpt = _music_channels[i].get_meta("openmpt")
			if is_instance_valid(openmpt):
				openmpt.queue_free()
		if &"OpenMPT" in _music_channels[i].name:
			i.queue_free()
		
		_music_channels[i].queue_free()
		_music_channels.erase(i)
