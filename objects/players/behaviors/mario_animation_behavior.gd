extends ByNodeScript

var player: PlayerMario
var sprite: AnimatedSprite2D


func _ready() -> void:
	player = node as PlayerMario
	sprite = node.sprite as AnimatedSprite2D


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
