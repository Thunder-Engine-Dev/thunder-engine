extends Area2D

const SMOKE = preload("res://engine/objects/effects/smoke/smoke.tscn")

@onready var staticbody: StaticBody2D = $Body

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group(&"unlocking_key"): return
	if !is_instance_valid(staticbody): return
	
	(func() -> void:
		staticbody.queue_free()
		var smoke = SMOKE.instantiate()
		smoke.global_position = global_position
		Scenes.current_scene.add_child(smoke)
		smoke.reset_physics_interpolation()
		Audio.play_sound(preload("res://engine/objects/items/grabbable_key/sounds/unlock.wav"), body)
		body.queue_free()
		
		var player: Player = Thunder._current_player
		if player:
			player.is_holding = false
			player.holding_item = null
	).call_deferred()
