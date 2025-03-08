extends Projectile

const explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
@export var jumping_speed: float = -450.0
@export var bounces_left: int = 3

var drown: bool = false

@onready var detector: ShapeCast2D = $Attack

signal run_out

func _physics_process(delta: float) -> void:
	super(delta)
	if !sprite_node: return
	sprite_node.rotation_degrees += 8 * (-1 if speed.x < 0 else 1) * Thunder.get_delta(delta)


func bounce(with_sound: bool = true, ceiling: bool = false) -> void:
	if bounces_left <= 0: return
	
	if with_sound:
		Audio.play_sound(preload("res://engine/objects/players/prefabs/sounds/swim.wav"), self)
	
	if !ceiling: jump(jumping_speed)
	else: vel_set_y(0)
	
	bounces_left -= 1
	
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform().call_method(func(node):
		node.position.y += 12
	)
	
	var _has_brick: bool
	for i in get_slide_collision_count():
		var _collision: KinematicCollision2D = get_slide_collision(i)
		if !_collision: continue
		
		var collider: Node2D = _collision.get_collider() as Node2D
		if (
			collider is StaticBumpingBlock &&
			collider.has_method(&"got_bumped")
		):
			collider.got_bumped(false)
			_has_brick = true
	if _has_brick:
		_fix_velocity.call_deferred(speed.x)

	if bounces_left == 0:
		run_out.emit()
		collision_layer = 0
		collision_mask = 0
		return


func _fix_velocity(old_speed: float) -> void:
	await get_tree().physics_frame
	if is_inside_tree():
		speed.x = old_speed


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 320):
			queue_free()
		return
	Data.values.score += 200
	ScoreText.new(str(200), self)
	queue_free()
