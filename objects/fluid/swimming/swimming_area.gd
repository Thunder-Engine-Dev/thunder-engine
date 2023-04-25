extends Area2D

const WATER_SPRAY: PackedScene = preload("res://engine/objects/effects/spray/water_spray.tscn")


func _ready() -> void:
	# Body in/out of water
	body_entered.connect(
		func(body: Node2D) -> void:
			if body is Player:
				body.in_water()
				body.states.set_state("swim")
				_spray(body, Vector2.UP * 16)
			elif body.is_in_group(&"#spray_body"):
				_spray(body, Vector2.ZERO)
	)
	
	body_exited.connect(
		func(body: Node2D) -> void:
			if body is Player:
				body.out_of_water()
				body.states.set_state("default")
				_spray(body, Vector2.UP * 16)
			elif body.is_in_group(&"#spray_body"):
				_spray(body, Vector2.ZERO)
	)
	# Player's head in/out of water
	area_entered.connect(
		func(area: Area2D) -> void:
			if area.get_parent() is Player:
				area.get_parent()._out_of_water = false
	)
	area_exited.connect(
		func(area: Area2D) -> void:
			if area.get_parent() is Player:
				area.get_parent()._out_of_water = true
	)


func _physics_process(delta: float) -> void:
	var player: Player = Thunder._current_player
	if !is_instance_valid(player): return
	if overlaps_body(player):
		player.states.set_state("swim")


func _spray(on: Node2D, offset: Vector2) -> void:
	NodeCreator.prepare_2d(WATER_SPRAY, on).bind_global_transform(offset).create_2d().call_method(
		func(spray: Node2D) -> void:
			if on is GravityBody2D:
				spray.translate(Vector2.UP * on.speed.y * on.get_physics_process_delta_time())
	)
