extends GravityBody2D

const ADD_EFFECT = preload("res://engine/shaders/add_effect.tres")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var _trail_position: Vector2
var _trail_end_position: Vector2
var _trail_frame: int = -1
var _trail_settings := Effect.TrailSettings.new()

func _ready() -> void:
	_trail_settings.fade_out_strength = 0.02
	_trail_settings.material = ADD_EFFECT
	_trail_settings.texture_filter = TEXTURE_FILTER_LINEAR
	Thunder._connect(collided_ceiling, turn_y, CONNECT_DEFERRED)
	Thunder._connect(collided_floor, turn_y, CONNECT_DEFERRED)
	Thunder._connect(collided_wall, turn_x, CONNECT_DEFERRED)

func _physics_process(delta: float) -> void:
	_trail_position = sprite.global_position
	_trail_frame = Engine.get_physics_frames()
	motion_process(delta)
	_trail_end_position = sprite.global_position
	
	var is_flipped: bool = speed.x < 0
	sprite.flip_h = is_flipped


func _on_timer_timeout() -> void:
	if !is_instance_valid(sprite): return
	var previous_position := sprite.global_position
	if _trail_frame == Engine.get_physics_frames() && previous_position.is_equal_approx(_trail_end_position):
		previous_position = _trail_position
	_trail_settings.texture = sprite.sprite_frames.get_frame_texture(&"trail", randi_range(0, 3))
	_trail_settings.z_index = z_index
	Effect.emit_trail(sprite, previous_position, _trail_settings)
