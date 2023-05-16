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

var _fading_musics: Array[Dictionary]
var _music_channels: Dictionary = {}

var _calculate_player_position = _lcpp.bind()


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _lcpp(ref: Node2D) -> Vector2:
	return ref.global_position


func _process(delta: float) -> void:
	_fading(delta)


func _create_2d_player(pos: Vector2, is_global: bool) -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	player.global_position = pos
	player.finished.connect(player.queue_free)
	if !is_global:
		Scenes.scene_changed.connect(player.queue_free.unbind(1))
	add_child(player)
	return player


func _create_1d_player(is_global: bool) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.finished.connect(player.queue_free)
	if !is_global:
		Scenes.pre_scene_changed.connect(player.queue_free)
	add_child(player)
	return player


func _fading(delta: float) -> void:
	for l in range(len(_fading_musics)):
		if l > len(_fading_musics) - 1: continue
		var i = _fading_musics[l]
		
		if !is_instance_valid(i.fading_music_player):
			_fading_musics.pop_at(l)
			continue
		
		var fading_music_player: AudioStreamPlayer = i.fading_music_player
		
		if !fading_music_player: continue
		
		match i.fading_method:
			FadingMethod.LINEAR: fading_music_player.volume_db = move_toward(fading_music_player.volume_db,i.fading_to,i.fading_weight)
			FadingMethod.LERP: fading_music_player.volume_db = lerp(fading_music_player.volume_db,i.fading_to,i.fading_weight)
			FadingMethod.SMOOTH_STEP: fading_music_player.volume_db = smoothstep(fading_music_player.volume_db,i.fading_to,i.fading_weight)
		
		if fading_music_player.volume_db == i.fading_to:
			if bool(i.fading_stop_after_fading):
				fading_music_player.stop()
			
			_fading_musics.pop_at(l)
			continue

## Play a sound with given [AudioStream] resource and bind the sound player to a [Node2D][br]
## [b]Note:[/b] This method creates [AudioStreamPlayer2D] which plays sound with pan changed according to its position to the center of screen, rather than [AudioStreamPlayer].[br]
## [param resource] is the sound stream you are going to install[br]
## [param ref] is the node to be bound[br]
## [param is_global] determines whether the sound can be played only in certain scene or global, the ones playing in the scene will be cut when calling [method Scenes.switch_to_scene][br]
## [param other_keys] is a [Dictionary] to extend the playing method, please see the [i][u]spell_keys[/u][/i] above
func play_sound(resource: AudioStream, ref: Node2D, is_global: bool = true, other_keys: Dictionary = {}) -> void:
	# Stop on empty sound to avoid crashes
	if resource == null: return
	
	var player = _create_2d_player(_calculate_player_position.call(ref), is_global)
	player.stream = resource
	player.play()
	
	if &"pitch" in other_keys && other_keys.pitch is float: player.pitch_scale = other_keys.pitch
	if &"ignore_pause" in other_keys && other_keys.ignore_pause: player.process_mode = Node.PROCESS_MODE_ALWAYS


## Play a sound with given [AudioStream] resource[br]
## [b]Note:[/b] This method creates [AudioStreamPlayer], and please see [method play_sound] to learn their differences.[br]
## [param resource] is the sound stream you are going to install[br]
## [param ref] is the node to be bound[br]
## [param is_global] determines whether the sound can be played only in certain scene or global, the ones playing in the scene will be cut when calling [method Scenes.switch_to_scene][br]
## [param other_keys] is a [Dictionary] to extend the playing method, please see the [i][u]spell_keys[/u][i] above
func play_1d_sound(resource: AudioStream, is_global: bool = true, other_keys: Dictionary = {}) -> void:
	# Stop on empty sound to avoid crashes
	if resource == null: return
	
	var player = _create_1d_player(is_global)
	player.stream = resource
	player.play()
	
	if &"pitch" in other_keys && other_keys.pitch is float: player.pitch_scale = other_keys.pitch
	if &"ignore_pause" in other_keys && other_keys.ignore_pause: player.process_mode = Node.PROCESS_MODE_ALWAYS


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
func play_music(resource: AudioStream, channel_id: int, other_keys: Dictionary = {}) -> void:
	if !_music_channels.has(channel_id) || !is_instance_valid(_music_channels[channel_id]):
		_music_channels[channel_id] = _create_1d_player(false)
	
	_music_channels[channel_id].stream = resource
	_music_channels[channel_id].play()
	
	if &"pitch" in other_keys && other_keys.pitch is float: _music_channels[channel_id].pitch_scale = other_keys.pitch
	if &"ignore_pause" in other_keys && other_keys.ignore_pause:_music_channels[channel_id].process_mode = Node.PROCESS_MODE_ALWAYS


## Fade a music player that is playing, and you can choose it's way to fade.[br]
## [param player] is the music player that is playing[br]
## [param to] is the final [member AudioStreamPlayer.volume_db] you wish[br]
## [param weight] is the strength/delta-value to fade the music[br]
## [param method] is the way to fade the music, different [param method] decides different [param weight] calculation. See [enum FadingMethod][br]
## [param stop_after_fading] determines whether the music stops playing after it fades to goal value. This is very useful when you are trying making fading-out-and-stop musics
func fade_music_1d_player(player: AudioStreamPlayer, to: float, weight: float, method: FadingMethod = FadingMethod.LINEAR, stop_after_fading: bool = false) -> void:
	var has_player: bool
	
	for i in _fading_musics:
		if i.fading_music_player == player:
			has_player = true
			continue
	
	if has_player: return
	
	_fading_musics.append(
		{
			fading_music_player = player,
			fading_to = to, 
			fading_weight = weight, 
			fading_method = method, 
			fading_stop_after_fading = stop_after_fading
		}
	)
