extends Area2D

var player

signal player_enter
signal player_exit

var _on_warp

func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint(): return
	if body == Thunder._current_player:
		player = body
		player_enter.emit()

func _on_body_exited(body: Node2D) -> void:
	if Engine.is_editor_hint(): return
	if body == Thunder._current_player && !_on_warp:
		player = null
		player_exit.emit()
