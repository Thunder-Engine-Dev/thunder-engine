extends Projectile

@export_category("Flame")
@export var flame_moving_y_speed: float = 150

var y_dir: int
var to_pos_y: float


func _physics_process(delta: float) -> void:
	super(delta)
	
	if flame_moving_y_speed == 0: return
	
	var pos: Vector2 = global_transform.affine_inverse().basis_xform(global_position)
	if pos.y != to_pos_y:
		pos = Vector2(pos.x, to_pos_y).rotated(global_rotation)
		global_position = global_position.move_toward(pos, flame_moving_y_speed * delta)
