extends ByNodeScript

# You need two custom vars:
# bullet: PackedScene
# bullet_speed: Vector2

var player: Player = Thunder._current_player

func _physics_process(delta: float) -> void:
	super(delta)
	
	if player.states.projectiles_count <= 0 || player.states.current_state == "dead":
		return
	
	if player._is_action_just_pressed("m_run"):
		NodeCreator.prepare_ins_2d(vars.bullet, player).call_method(func(ins: GravityBody2D) -> void:
			ins.speed = vars.bullet_speed
			if player.sprite.flip_h: ins.speed.x = -abs(ins.speed.x)
		).create_2d()
		
		player.states.projectiles_count -= 1
		player.states.launch_timer = 2
		
		Audio.play_sound(
			preload("res://engine/objects/projectiles/sounds/shoot.wav"),
			player
		)
