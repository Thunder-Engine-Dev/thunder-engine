extends GeneralMovementBody2D

@export var speed_cap: float = 200
@export var turn_speed: float = 5
var speed_modifier: float = 0

func _physics_process(delta: float) -> void:
	super(delta)
	
	var right_of_player: int = global_position.rotated(-global_rotation).x > Thunder._current_player.global_position.rotated(-global_rotation).x
	if right_of_player == 0: right_of_player = -1
	
	speed.x = move_toward(speed.x, turn_speed * right_of_player, turn_speed * right_of_player)
	speed.x = clamp(speed.x, -speed_cap, speed_cap)
	
	
#	if dir == (1 if right_of_player else -1):
#		if speed.x < speed_cap:
#			accelerate_x(speed.x, turn_speed * dir)
#		else:
#			dir = -1 if right_of_player else 1
#	elif abs(speed.x) > 0:
#		speed.x -= turn_speed * Thunder.get_delta(delta)
