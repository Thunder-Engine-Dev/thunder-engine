extends Node

@onready var player: Player = Thunder._current_player
var _player_speed: float = 200

func _ready() -> void:
	await get_parent().ready
	player = Thunder._current_player
	player.completed = true


func _physics_process(delta: float) -> void:
	player.speed.x = _player_speed
	
	if player.global_position.x > 160:
		_player_speed = move_toward(_player_speed, 100, delta * 80)
	
		if player.is_on_wall():
			player.left_right = 1
