extends ByNodeScript

var player: Mario
var sprite: AnimatedSprite2D


func _ready() -> void:
	player = node as Mario
	sprite = node.sprite as AnimatedSprite2D
	
	player.suit_appeared.connect(
		func() -> void:
			if !sprite: return
			sprite.play(&"appear")
			await player.get_tree().create_timer(1, false, true)
			sprite.play(&"default")
	)
	player.swam.connect(
		func() -> void:
			if !sprite: return
			if sprite.animation == &"swim" && sprite.frame > 2: sprite.frame = 0
	)
	
	sprite.animation_looped.connect(
		func() -> void:
			if !sprite: return
			match sprite.animation:
				&"swim": sprite.frame = sprite.sprite_frames.get_frame_count(sprite.animation) - 2
	)
	sprite.animation_finished.connect(
		func() -> void:
			if !sprite: return
			if sprite.animation == &"attack": sprite.play(&"default")
	)


func _physics_process(delta: float) -> void:
	delta = player.get_physics_process_delta_time()
	_animation_process(delta)


func _animation_process(delta: float) -> void:
	if !sprite: return
	if sprite.animation in [&"appear", &"attack"]: return
	
	if player.direction != 0:
		sprite.flip_h = (player.direction < 0)
	sprite.speed_scale = 1
	
	if player.is_on_floor():
		if player.speed.x != 0:
			sprite.play(&"walk")
			sprite.speed_scale = clampf(abs(player.speed.x) * delta * 1.5, 1, 6)
		else:
			sprite.play(&"default")
		if player.is_crouching:
			sprite.play(&"crouch")
	elif player.is_underwater:
		sprite.play(&"swim")
	else:
		sprite.play(&"jump")
