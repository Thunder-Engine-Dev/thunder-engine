extends Node

@onready var player: Player = Thunder._current_player
@onready var jump_marker = $JumpMarker
var _player_speed: float = 150
var has_jumped: bool

func _ready() -> void:
	await get_parent().ready
	player = Thunder._current_player
	player.completed = true


func _physics_process(delta: float) -> void:
	player.speed.x = _player_speed
	
	if player.global_position.x > 360:
		_player_speed = move_toward(_player_speed, 100, delta * 80)
	
	if !has_jumped && player.global_position.x > jump_marker.global_position.x:
		player.jump(-500)
		Audio.play_sound(player.suit.physics_config.sound_jump, player, false)
		has_jumped = true
	
	if player.global_position.y > 600:
		Scenes.current_scene._start_transition()
