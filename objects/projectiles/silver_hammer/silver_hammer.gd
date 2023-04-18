extends Projectile

const explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
#@export var jumping_speed: float = -450.0
@export var bounces_left: int = 2

var drown: bool = false

@onready var detector: ShapeCast2D = $Attack

signal run_out


func _physics_process(delta: float) -> void:
	super(delta)
	if !sprite_node: return
	sprite_node.rotation_degrees += 50 * (-1 if speed.x < 0 else 1) * Thunder.get_delta(delta)


func bounce(with_sound: bool = true, ceiling: bool = false) -> void:
	if bounces_left <= 0: return
	
	if with_sound:
		Audio.play_sound(preload("res://engine/objects/mario/sounds/kick.wav"), self)
	
	turn_x()
	turn_y()
	speed.x *= randf_range(1.1, 1.3)
	speed.y *= randf_range(0.7, 0.9)
	
	bounces_left -= 1
	
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	
	if bounces_left == 0:
		run_out.emit()
		collision_layer = 0
		collision_mask = 0
		return
	
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		if !collision: continue
		
		var collider: Node2D = collision.get_collider() as Node2D
		if collider is StaticBumpingBlock && collider.has_method(&"bricks_break"):
			collider.bricks_break()
