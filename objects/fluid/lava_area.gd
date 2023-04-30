extends Area2D

const LAVA_SPRAY: PackedScene = preload("res://engine/objects/effects/sprays/lava_spray.tscn")


func _ready() -> void:
	# Body in/out of water
	body_entered.connect(
		func(body: Node2D) -> void:
			if body == Thunder._current_player:
				body.die()
			if body.is_in_group(&"#lava_body"):
				_spray(body, Vector2.ZERO)
	)
	
	body_exited.connect(
		func(body: Node2D) -> void:
			if body.is_in_group(&"#lava_body"):
				_spray(body, Vector2.ZERO)
	)


func _spray(on: Node2D, offset: Vector2) -> void:
	NodeCreator.prepare_2d(LAVA_SPRAY, on).bind_global_transform(offset).create_2d().call_method(
		func(spray: Node2D) -> void:
			if on is GravityBody2D:
				spray.translate(Vector2.UP * on.speed.y * on.get_physics_process_delta_time())
	)
