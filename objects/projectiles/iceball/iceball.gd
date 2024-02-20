extends Projectile

const explosion_effect = preload("res://engine/objects/effects/smoke/smoke.tscn")

@onready var vision: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@export var jumping_speed: float = -350.0
var bounces_left: int = 2


func _ready() -> void:
	await get_tree().physics_frame
	if (
		belongs_to == Data.PROJECTILE_BELONGS.ENEMY &&
		!vision.is_on_screen()
	):
		queue_free()


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
	#var effect: Callable = func(eff: Node2D) -> void:
	#	eff.global_transform = global_transform
	
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	queue_free()


func expand_vision(_scale: Vector2) -> void:
	await ready
	if vision: vision.scale = _scale


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 320):
			queue_free()
		return
	Data.values.score += 100
	ScoreText.new(str(100), self)
	queue_free()
