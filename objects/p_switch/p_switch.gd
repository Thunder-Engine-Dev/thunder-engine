extends StaticBody2D


func active() -> void:
	$Collision.set_deferred("disabled", true)
	$Activator.queue_free()
	
	$Sprite.animation = &"activated"
	
	var level = Scenes.current_scene
	
	if level is Level:
		level.toggle_p_switch(10)
	
	await get_tree().create_timer(1.5).timeout
	
	queue_free()


func _on_activator_body_entered(body):
	if body == Thunder._current_player:
		active()
