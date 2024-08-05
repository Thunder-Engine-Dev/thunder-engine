extends Area2D

signal player_enter
signal player_exit

var player: Player

@export var only_once: bool = false
var passed: bool = false

func _ready() -> void:
	body_entered.connect(func(body: Node2D):
		if only_once && passed: return
		if body == Thunder._current_player:
			player = body
			player_enter.emit()
			passed = true
	)
	body_exited.connect(func(body: Node2D) -> void:
		if body == Thunder._current_player:
			player = null
			player_exit.emit()
	)
