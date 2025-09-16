extends Projectile

const explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
#@export var jumping_speed: float = -450.0
@export var bounces_left: int = 2
@export var remove_offscreen_after: float = 2.0
@export var remove_top_offscreen: bool = false

var drown: bool = false

@onready var detector: ShapeCast2D = $Attack

signal run_out

func _ready() -> void:
	if !remove_top_offscreen:
		vision_node.rect.size.y = 512
	super()
	offscreen_handler(remove_offscreen_after)


func _physics_process(delta: float) -> void:
	super(delta)
	if !sprite_node: return
	sprite_node.rotation_degrees += 50 * (-1 if speed.x < 0 else 1) * Thunder.get_delta(delta)


func bounce(with_sound: bool = true, ceiling: bool = false) -> void:
	if bounces_left <= 0: return
	
	if with_sound:
		Audio.play_sound(preload("res://engine/objects/players/prefabs/sounds/kick.wav"), self)
	
	turn_x()
	turn_y()
	speed.x *= Thunder.rng.get_randf_range(1.1, 1.3)
	speed.y *= Thunder.rng.get_randf_range(0.7, 0.9)
	
	bounces_left -= 1
	
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	
	for i in get_slide_collision_count():
		var _collision: KinematicCollision2D = get_slide_collision(i)
		if !_collision: continue
		
		var collider: Node2D = _collision.get_collider() as Node2D
		if collider is StaticBumpingBlock && collider.has_method(&"bricks_break"):
			collider.bricks_break()
	
	if bounces_left == 0:
		run_out.emit()
		collision_layer = 0
		collision_mask = 0
		return


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 2048):
			queue_free()
		return
	Data.add_score(200)
	ScoreText.new(str(200), self)
	queue_free()
