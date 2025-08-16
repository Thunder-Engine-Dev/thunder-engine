extends Sprite2D

@export var speed: float = 50
var fake_pos := Vector2.ZERO

@export var init_pos = 320

func _physics_process(delta):
	var cam: Camera2D = Thunder._current_camera
	if !cam: return
	position.x -= speed * delta
	fake_pos.x = init_pos + cam.get_screen_center_position().x - 320
	while position.x >= fake_pos.x + 64:
		position.x -= 64
		reset_physics_interpolation()
	while position.x < fake_pos.x - 64:
		position.x += 64
		reset_physics_interpolation()
