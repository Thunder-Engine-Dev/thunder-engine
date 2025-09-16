extends Projectile

const explosion_effect = preload("res://engine/objects/effects/smoke/smoke.tscn")

@export var jumping_speed: float = -350.0
@export var remove_offscreen_after: float = 3.0
@export var remove_top_offscreen: bool = false
var bounces_left: int = 2


func _ready() -> void:
	if belongs_to == Data.PROJECTILE_BELONGS.PLAYER:
		remove_offscreen_after = 2.0
	if !remove_top_offscreen:
		vision_node.rect.size.y = 512
	offscreen_handler(remove_offscreen_after)
	super()


func _physics_process(delta: float) -> void:
	super(delta)
	delta = Thunder.get_delta(delta)
	speed.x = lerp(speed.x, 0.0, 0.015 * delta)
	if !sprite_node: return
	sprite_node.rotation_degrees += 12 * (-1 if speed.x < 0 else 1) * delta
	if speed.x == 0: explode()


func jump(jspeed:float = jumping_speed) -> void:
	if bounces_left > 0:
		super(jspeed)
		bounces_left -= 1
	else:
		explode()


func explode():
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	queue_free()


func expand_vision(_scale: Vector2) -> void:
	await ready
	if vision_node: vision_node.scale = _scale


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 2048):
			queue_free()
		return
	Data.add_score(100)
	ScoreText.new(str(100), self)
	queue_free()
