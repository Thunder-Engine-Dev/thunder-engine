extends Powerup

@onready var area_2d: Area2D = $Area2D

func _physics_process(delta: float) -> void:
	super(delta)
	if appear_distance: return
	
	if is_zero_approx(speed.x):
		vel_set_x(150)
	
	var underwater: bool
	for i in area_2d.get_overlapping_areas():
		if i.is_in_group(&"#water"):
			underwater = true
			break
	if underwater:
		gravity_scale = 0.2
		max_falling_speed = 200
	else:
		gravity_scale = 0.4
		max_falling_speed = 750
	
	if is_on_floor():
		jump(250 if underwater else 350)
