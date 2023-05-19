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


func _input(event: InputEvent) -> void:
	if player && event.is_action_pressed(player.control.up):
		player.is_climbing = true
