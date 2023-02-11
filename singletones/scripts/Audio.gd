extends Node

enum FadingMethod {LINEAR,LERP,SMOOTH_STEP}

var fading_musics: Array[Dictionary]
var music_channels: Dictionary = {}

var _calculate_player_position = func(ref: Node2D) -> Vector2:
	return ref.global_position

func _process(delta: float) -> void:
	_fading(delta)


func _create_2d_player(pos: Vector2, is_global: bool) -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	player.global_position = pos
	player.finished.connect(player.queue_free)
	if !is_global:
		Scenes.scene_changed_notification.connect(player.queue_free)
	add_child(player)
	return player


func _create_1d_player(is_global: bool) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.finished.connect(player.queue_free)
	if !is_global:
		Scenes.scene_changed_notification.connect(player.queue_free)
	add_child(player)
	return player


func _fading(delta: float) -> void:
	for i in fading_musics:
		var fading_music_player: AudioStreamPlayer = i.fading_music_player
		
		if !fading_music_player: continue
		
		match i.fading_method:
			FadingMethod.LINEAR: fading_music_player.volume_db = move_toward(fading_music_player.volume_db,i.fading_to,i.fading_weight)
			FadingMethod.LERP: fading_music_player.volume_db = lerp(fading_music_player.volume_db,i.fading_to,i.fading_weight)
			FadingMethod.SMOOTH_STEP: fading_music_player.volume_db = smoothstep(fading_music_player.volume_db,i.fading_to,i.fading_weight)
		
		if fading_music_player.volume_db == i.fading_to:
			if bool(i.fading_stop_after_fading):
				fading_music_player.stop()
			continue


func play_sound(resource: AudioStream, ref: Node2D, is_global: bool = true, other_keys: Dictionary = {}) -> void:
	# Stop on empty sound to avoid crashes
	if resource == null: return
	
	var player = _create_2d_player(_calculate_player_position.call(ref), is_global)
	player.stream = resource
	player.play()
	
	if &"pitch" in other_keys && other_keys.pitch is float: player.pitch_scale = other_keys.pitch

func play_1d_sound(resource: AudioStream, is_global: bool = true, other_keys: Dictionary = {}) -> void:
	# Stop on empty sound to avoid crashes
	if resource == null: return
	
	var player = _create_1d_player(is_global)
	player.stream = resource
	player.play()
	
	if &"pitch" in other_keys && other_keys.pitch is float: player.pitch_scale = other_keys.pitch

func play_music(resource: AudioStream, channel_id: int, other_keys: Dictionary = {}) -> void:
	if !music_channels.has(channel_id) || !is_instance_valid(music_channels[channel_id]):
		music_channels[channel_id] = _create_1d_player(false)
	
	music_channels[channel_id].stream = resource
	music_channels[channel_id].play()
	
	if &"pitch" in other_keys && other_keys.pitch is float: music_channels[channel_id].pitch_scale = other_keys.pitch

func fade_music_1d_player(player: AudioStreamPlayer, to: float, weight: float, method: FadingMethod = FadingMethod.LINEAR, stop_after_fading: bool = false) -> void:
	var has_player:bool
	
	for i in fading_musics:
		if i.fading_music_player == player:
			has_player = true
			continue
	
	if has_player: return
	
	fading_musics.append(
		{
			fading_music_player = player,
			fading_to = to, 
			fading_weight = weight, 
			fading_method = method, 
			fading_stop_after_fading = stop_after_fading
		}
	)
