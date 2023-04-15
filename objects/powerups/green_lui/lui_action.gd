extends ByNodeScript

const trail = preload("res://engine/objects/effects/trail/trail.tscn")

var trail_timer: float

func _physics_process(delta: float) -> void:
	var player = Thunder._current_player
	
	# Higher and consistent jumps
	if !player.is_on_floor() && Input.is_action_pressed(player.config.control_jump) && player.velocity_local.y < 0:
		if abs(player.velocity_local.x) < 1:
			player.velocity_local.y -= 10 * Thunder.get_delta(delta)
		else:
			player.velocity_local.y -= 5 * Thunder.get_delta(delta)
	
	# Trail effect
	if trail_timer > 0.0: trail_timer -= 1 * Thunder.get_delta(delta)
	if !player.is_on_floor() && trail_timer <= 0.0:
		trail_timer = 1.5
		Trail.trail(
			player, 
			player.sprite.sprite_frames.get_frame_texture(player.sprite.animation, player.sprite.frame),
			player.sprite.offset,
			player.sprite.flip_h,
			player.sprite.flip_v,
			false
		)
#		var trail_node = trail.instantiate()
#		Scenes.current_scene.add_child(trail_node)
#		trail_node.global_transform = player.sprite.global_transform
