extends GravityBody2D

const ADD_EFFECT = preload("res://engine/shaders/add_effect.tres")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	Thunder._connect(collided_ceiling, turn_y, CONNECT_DEFERRED)
	Thunder._connect(collided_floor, turn_y, CONNECT_DEFERRED)
	Thunder._connect(collided_wall, turn_x, CONNECT_DEFERRED)

func _physics_process(delta: float) -> void:
	motion_process(delta)
	
	var is_flipped: bool = speed.x < 0
	sprite.flip_h = is_flipped


func _on_timer_timeout() -> void:
	if !is_instance_valid(sprite): return
	# Trail effect
	Effect.trail(
		self,
		sprite.sprite_frames.get_frame_texture(&"trail", randi_range(0, 3)),
		sprite.position,
		sprite.flip_h,
		sprite.flip_v,
		true,
		0.02,
		1.0,
		ADD_EFFECT,
		0,
		true,
		TEXTURE_FILTER_LINEAR
	)
