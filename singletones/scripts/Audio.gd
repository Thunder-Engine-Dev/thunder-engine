extends Node


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


func play_sound(resource: AudioStream, ref: Node2D, is_global: bool = true) -> void:
	var player = _create_2d_player(_calculate_player_position(ref), is_global)
	player.stream = resource
	player.play()
