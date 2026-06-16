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
	if player && !player.is_holding && (
		player.up_down < -0.3 ||
		(player.up_down > 0.3 && !player.is_on_floor())
	):
		player.is_climbing = true
		player._has_jumped = false
