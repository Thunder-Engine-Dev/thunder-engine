extends Area2D

const LAVA_SPRAY: PackedScene = preload("res://engine/objects/effects/sprays/lava_spray.tscn")

signal body_got_in_lava_at(pos: Vector2)
signal area_got_in_lava_at(pos: Vector2)

func _ready() -> void:
	# Body in/out of water
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	body_exited.connect(_on_body_exited)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"#lava_body"):
		self._spray.call_deferred(area, Vector2.ZERO)
		if area.has_method(&"got_in_lava"):
			area.got_in_lava()
			area_got_in_lava_at.emit(area.global_position)
	if area.has_node(^"EnemyAttacked"):
		var enemy_att = area.get_node(^"EnemyAttacked")
		if enemy_att.killing_immune.has(&"lava"):
			if enemy_att.killing_immune.lava == false:
				enemy_att.got_killed(&"lava", [&"no_score"])


func _on_body_entered(body: Node2D) -> void:
	if !is_instance_valid(body) || body.is_queued_for_deletion():
		return
	if body == Thunder._current_player:
		if !body.is_starman():
			body.die()
		elif body.has_node("Underwater") && !body.get(&"is_underwater"):
			var underwater: Node = body.get_node("Underwater")
			underwater.in_water()
			Thunder._connect(body.timer_starman.timeout, _player_death_after_starman, CONNECT_ONE_SHOT)
	if body.is_in_group(&"#lava_body"):
		if body is Player && body.warp != Player.Warp.NONE:
			return
		self._spray.call_deferred(body, Vector2.ZERO)
		if body.has_method(&"got_in_lava"):
			body.got_in_lava()
			body_got_in_lava_at.emit(body.global_position)


func _on_body_exited(body: Node2D) -> void:
	if !is_instance_valid(body) || body.is_queued_for_deletion():
		return
	if body == Thunder._current_player && body.is_starman() && body.has_node("Underwater") && body.get(&"is_underwater"):
		var underwater: Node = body.get_node("Underwater")
		underwater.out_of_water()
		Thunder._disconnect(body.timer_starman.timeout, _player_death_after_starman)
	if body.is_in_group(&"#lava_body"):
		if body is Player && body.warp != Player.Warp.NONE:
			return
		self._spray.call_deferred(body, Vector2.ZERO)


func _spray(on: Node2D, offset: Vector2) -> void:
	NodeCreator.prepare_2d(LAVA_SPRAY, on).bind_global_transform(offset).create_2d().call_method(
		func(spray: Node2D) -> void:
			if on is GravityBody2D:
				spray.translate(Vector2.UP * on.speed.y * on.get_physics_process_delta_time())
	)


func _player_death_after_starman() -> void:
	var pl := Thunder._current_player
	if !pl || pl.completed: return
	if get_overlapping_bodies().has(pl):
		await get_tree().physics_frame
		if !is_instance_valid(pl): return
		pl.die()
