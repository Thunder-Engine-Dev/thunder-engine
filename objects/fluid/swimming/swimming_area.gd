extends Area2D

const WATER_SPRAY: PackedScene = preload("res://engine/objects/effects/sprays/water_spray.tscn")


func _ready() -> void:
	# Body in/out of water
	body_entered.connect(
		func(body: Node2D) -> void:
			if body.has_node("Underwater"):
				var underwater: Node = body.get_node("Underwater")
				underwater.in_water()
				_spray(body, underwater.spray_offset)
	)
	body_exited.connect(
		func(body: Node2D) -> void:
			if body.has_node("Underwater"):
				var underwater: Node = body.get_node("Underwater")
				underwater.out_of_water()
				_spray(body, underwater.spray_offset)
	)


func _spray(on: Node2D, offset: Vector2) -> void:
	NodeCreator.prepare_2d(WATER_SPRAY, on).bind_global_transform(offset).create_2d().call_method(
		func(spray: Node2D) -> void:
			if on is GravityBody2D:
				spray.translate(Vector2.UP * on.speed.y * on.get_physics_process_delta_time())
	)
