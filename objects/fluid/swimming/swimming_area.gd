extends Area2D

const WATER_SPRAY: PackedScene = preload("res://engine/objects/effects/sprays/water_spray.tscn")

@export var can_swim: bool = true

var _is_ready: bool

signal body_got_in_water_at(pos: Vector2)
signal area_got_in_water_at(pos: Vector2)

func _ready() -> void:
	# Body in/out of water
	body_entered.connect(
		func(body: Node2D) -> void:
			if body.has_node("Underwater") && !body.get(&"is_underwater"):
				var underwater: Node = body.get_node("Underwater")
				if can_swim:
					underwater.in_water()
				if !_is_ready:
					return
				if "warp" in body && body.warp != 0:
					return
				if "spray_offset" in underwater:
					self._spray.call_deferred(body, underwater.spray_offset)
			if body.is_in_group(&"#water_body") && body:
				if body is Player && body.warp != Player.Warp.NONE:
					return
				if _is_ready:
					self._spray.call_deferred(body, Vector2(0, 8))
				if body.has_method(&"got_in_water"):
					body.got_in_water()
					body_got_in_water_at.emit(body.global_position)
	)
	body_exited.connect(
		func(body: Node2D) -> void:
			if !is_instance_valid(body) || body.is_queued_for_deletion():
				return
			if body.has_node("Underwater") && body.get(&"is_underwater"):
				var underwater: Node = body.get_node("Underwater")
				if can_swim:
					underwater.out_of_water()
				if !_is_ready:
					return
				if "warp" in body && body.warp != 0:
					return
				if "spray_offset" in underwater:
					self._spray.call_deferred(body, underwater.spray_offset)
			if body.is_in_group(&"#water_body"):
				if body is Player && body.warp != Player.Warp.NONE:
					return
				if _is_ready:
					self._spray.call_deferred(body, Vector2(0, 8))
	)
	area_entered.connect(
		func(area: Area2D) -> void:
			if area.is_in_group(&"#water_body"):
				if _is_ready:
					self._spray.call_deferred(area, Vector2(0, 8))
				if area.has_method(&"got_in_water"):
					area.got_in_water()
					area_got_in_water_at.emit(area.global_position)
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
