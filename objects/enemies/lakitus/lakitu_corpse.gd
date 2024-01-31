extends GeneralMovementBody2D

var body: Node2D
var pos: Vector2

var respawn_delay: float
var respawn_offset: float
var center: Vector2


func _ready() -> void:
	super()
	
	_center()
	var pos_to: Vector2 = (pos - center).project(Vector2.UP).rotated(global_rotation)
	
	if respawn_delay > 0:
		get_tree().create_timer(respawn_delay, false).timeout.connect(
			func() -> void:
				add_sibling(body)
				body.global_position = (
					center + pos_to.rotated(body.global_rotation) - Vector2.RIGHT \
					* body.leaving_direction * \
					(get_viewport_rect().size.x / 2 + 64 + respawn_offset)
				)
				queue_free()
		)


func _physics_process(delta: float) -> void:
	super(delta)
	
	if respawn_delay > 0:
		_center()
		return
	if !Thunder.view.screen_dir(global_position, get_global_gravity_dir(), 512):
		queue_free()


func _center() -> void:
	center = (
		get_viewport_transform().affine_inverse().get_origin() + get_viewport_rect().get_center()
	)
