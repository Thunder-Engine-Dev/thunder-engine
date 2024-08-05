extends Area2D

const LAVA_SPRAY: PackedScene = preload("res://engine/objects/effects/sprays/lava_spray.tscn")

signal area_got_in_lava_at(pos: Vector2)

func _ready() -> void:
	# Body in/out of water
	body_entered.connect(
		func(body: Node2D) -> void:
			if body == Thunder._current_player:
				body.die()
			if body.is_in_group(&"#lava_body"):
				self._spray.call_deferred(body, Vector2.ZERO)
	)
	area_entered.connect(
		func(area: Area2D) -> void:
			if area.is_in_group(&"#lava_body"):
				self._spray.call_deferred(area, Vector2.ZERO)
				if area.has_method(&"got_in_lava"):
					area.got_in_lava()
					area_got_in_lava_at.emit(area.global_position)
	)
	
	body_exited.connect(
		func(body: Node2D) -> void:
			if body.is_in_group(&"#lava_body"):
				self._spray.call_deferred(body, Vector2.ZERO)
	)


func _spray(on: Node2D, offset: Vector2) -> void:
	NodeCreator.prepare_2d(LAVA_SPRAY, on).bind_global_transform(offset).create_2d().call_method(
		func(spray: Node2D) -> void:
			if on is GravityBody2D:
				spray.translate(Vector2.UP * on.speed.y * on.get_physics_process_delta_time())
	)
