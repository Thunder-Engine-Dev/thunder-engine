extends "res://engine/objects/players/behaviors/player_animation_behavior.gd"


#= Connected
func _suit_appeared() -> void:
	if !sprite: return
	sprite.play(&"appear")
	sprite.speed_scale = 1
	
	_setup_tweaks()
	
	await player.get_tree().create_timer(0.02 if _suit_pause_tweak else player.suit.appearing_time_sec, false, true).timeout
	if sprite.animation == &"appear": sprite.play(&"default")


func _swam() -> void:
	if !sprite: return
	if sprite.animation in [&"swim", &"swim_up", &"swim_down"]:
		sprite.frame = 0
		sprite.play()


#= Main
func _animation_non_warping_process(delta: float) -> void:
	if sprite.animation in [&"appear", &"attack", &"grab", &"kick"]: return
	sprite.sprite_frames.set_animation_loop(&"walk", true)
	# Climbing
	if player.is_climbing:
		return _animation_climbing_process(delta)
	if player.is_sliding:
		return _animation_sliding_process(delta)
	# Non-climbing
	player.skid.emitting = false
	if player.is_underwater:
		return _animation_swimming_process(delta)
	if player.is_on_floor() || player.coyote_time > 0.0:
		sprite.sprite_frames.set_animation_loop(&"walk", false)
		_animation_floor_process(delta)
	else:
		_animation_jumping_process(delta)

func _animation_floor_process(delta: float) -> void:
	super(delta)
	player.skid.emitting = false
	sprite.speed_scale = 1
	if player.is_on_floor() && player.completed && sprite.animation == &"walk":
		sprite.speed_scale = 3
		sprite.play()


func _animation_swimming_process(delta: float) -> void:
	_p_run_enabled = false
	if player.up_down > 0 && player.left_right == 0:
		if sprite.animation == &"swim_down": return
		
		#sprite.frame = sprite.sprite_frames.get_frame_count(&"swim_down") - 1
		var current_frame = sprite.get_frame()
		var current_progress = sprite.get_frame_progress()
		_play_anim(&"swim_down" if !player.is_holding else &"hold_swim")
		sprite.set_frame_and_progress(current_frame, current_progress)

	elif player.up_down < 0 && player.left_right == 0:
		if sprite.animation == &"swim_up": return
		
		var current_frame = sprite.get_frame()
		var current_progress = sprite.get_frame_progress()
		_play_anim(&"swim_up" if !player.is_holding else &"hold_swim")
		sprite.set_frame_and_progress(current_frame, current_progress)
		
	else:
		if sprite.animation == &"swim": return
		var current_frame = sprite.get_frame()
		var current_progress = sprite.get_frame_progress()
		_play_anim(_get_animation_prefixed(&"swim"))
		sprite.set_frame_and_progress(current_frame, current_progress)


func _animation_warping_process() -> void:
	player.skid.emitting = false
	_idle_timer = 0.0
	match player.warp_dir:
		Player.WarpDir.DOWN:
			_play_anim(&"warp" if _warp_tweak else _get_animation_prefixed(&"default"))
		Player.WarpDir.UP:
			_play_anim(&"warp" if _warp_tweak else _get_animation_prefixed(&"jump"))
		Player.WarpDir.LEFT, Player.WarpDir.RIGHT:
			player.direction = -1 if player.warp_dir == Player.WarpDir.LEFT else 1
			_play_anim(_get_animation_prefixed(&"walk"))
			sprite.speed_scale = 2
			sprite.play()
