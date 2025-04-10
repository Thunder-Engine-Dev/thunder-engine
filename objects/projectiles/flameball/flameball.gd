extends Projectile

const explosion_effect = preload("res://engine/objects/effects/explosion/explosion.tscn")
@export var remove_offscreen_after: float = 0.8
@export var remove_top_offscreen: bool = false

func _ready() -> void:
	if !remove_top_offscreen:
		vision_node.rect.size.y = 512
	offscreen_handler(remove_offscreen_after)


func _physics_process(delta: float) -> void:
	super(delta)
	if !sprite_node: return
	sprite_node.rotation_degrees += 24 * (-1 if speed.x < 0 else 1) * Thunder.get_delta(delta)


func explode():
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	queue_free()
