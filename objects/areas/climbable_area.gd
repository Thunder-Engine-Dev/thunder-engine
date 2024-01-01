extends Area2D

var player: Player


func _ready() -> void:
	body_entered.connect(
		func(body: Node2D) -> void:
			if body != Thunder._current_player: return
			player = body
	)
	body_exited.connect(
		func(body: Node2D) -> void:
			if body != Thunder._current_player: return
			player.is_climbing = false
			player = null
	)


func _physics_process(delta: float) -> void:
	if player && (
		Input.is_action_pressed(player.control.up) ||
		(Input.is_action_pressed(player.control.down) && !player.is_on_floor())
	):
		player.is_climbing = true
		player._physics_behavior._has_jumped = false
