extends Node

enum FadingMethod {LINEAR,LERP,SMOOTH_STEP}

var fading_musics: Array[Dictionary]


func _process(delta: float) -> void:
	_fading(delta)


func _create_2d_player(pos: Vector2, is_global: bool) -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	player.global_position = pos
	player.finished.connect(player.queue_free)
	if !is_global:
		Thunder.stage_changed.connect(player.queue_free)
	add_child(player)
	return player


func _create_1d_player(pos: Vector2, is_global: bool) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.finished.connect(player.queue_free)
	if !is_global:
		Thunder.stage_changed.connect(player.queue_free)
	add_child(player)
	return player


func _calculate_player_position(ref: Node2D) -> Vector2:
	return ref.global_position

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


func play_sound(resource: AudioStream, ref: Node2D, is_global: bool = true) -> void:
	var player = _create_2d_player(_calculate_player_position(ref), is_global)
	player.stream = resource
	player.play()

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
