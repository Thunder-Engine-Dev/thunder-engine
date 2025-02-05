extends Projectile

@export_category("Flame")
@export var rotating_speed: float = 2
var flame_moving_y_speed: float = 150

var y_dir: int
var to_pos_y: float


func _physics_process(delta: float) -> void:
	if speed.x < 0:
		global_rotation -= PI
		speed.x = abs(speed.x)
	position += abs(speed).rotated(global_rotation) * delta
	
	var player = Thunder._current_player
	if !player: return
	var target = (player.global_position - global_position).angle()
	
	global_rotation = rotate_toward(global_rotation, target, rotating_speed * delta)
