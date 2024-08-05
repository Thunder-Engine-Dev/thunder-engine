extends Projectile

const explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
@export var jumping_speed: float = -450.0
@export var bounces_left: int = 3

var drown: bool = false

@onready var detector: ShapeCast2D = $Attack

signal run_out


func bounce(with_sound: bool = true, ceiling: bool = false) -> void:
	if bounces_left <= 0: return
	
	if with_sound:
		Audio.play_sound(preload("res://engine/objects/projectiles/sounds/stun.wav"), self)
	
	turn_x()
	
	if !ceiling: jump(jumping_speed)
	else: vel_set_y(0)
	
	bounces_left -= 1
	
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform().call_method(func(node):
		node.position.y += 12
	)
	
	for i in get_slide_collision_count():
		var _collision: KinematicCollision2D = get_slide_collision(i)
		if !_collision: continue
		
		var collider: Node2D = _collision.get_collider() as Node2D
		if (
			collider is StaticBumpingBlock &&
			collider.has_method(&"got_bumped")
		):
			collider.got_bumped(self)

	if bounces_left == 0:
		run_out.emit()
		collision_layer = 0
		collision_mask = 0
		return


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 320):
			queue_free()
		return
	Data.values.score += 200
	ScoreText.new(str(200), self)
	queue_free()
