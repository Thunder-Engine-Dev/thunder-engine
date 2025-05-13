extends Area2D

const WATER_SPRAY: PackedScene = preload("res://engine/objects/effects/sprays/water_spray.tscn")
var _is_ready: bool

func _ready() -> void:
	# Body in/out of water
	body_entered.connect(
		func(body: Node2D) -> void:
			if body.has_node("Underwater"):
				var underwater: Node = body.get_node("Underwater")
				underwater.in_water()
				if !_is_ready:
					return
				if "warp" in body && body.warp != 0:
					return
				if "spray_offset" in underwater:
					self._spray.call_deferred(body, underwater.spray_offset)
	)
	body_exited.connect(
		func(body: Node2D) -> void:
			if !is_instance_valid(body) || body.is_queued_for_deletion():
				return
			if body.has_node("Underwater"):
				var underwater: Node = body.get_node("Underwater")
				underwater.out_of_water()
				if !_is_ready:
					return
				if "warp" in body && body.warp != 0:
					return
				if "spray_offset" in underwater:
					self._spray.call_deferred(body, underwater.spray_offset)
	)
	if Scenes.current_scene is Stage2D:
		await Scenes.current_scene.stage_ready
	await get_tree().physics_frame
	_is_ready = true


func _spray(on: Node2D, offset: Vector2) -> void:
	NodeCreator.prepare_2d(WATER_SPRAY, on).bind_global_transform(offset).create_2d().call_method(
		func(spray: Node2D) -> void:
			if on is GravityBody2D:
				spray.translate(Vector2.UP * on.speed.y * on.get_physics_process_delta_time())
	)
