extends Projectile

const explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
const BUBBLE = preload("res://engine/objects/effects/bubble/bubble.tscn")
@export var jumping_speed: float = -450.0
@export var bounces_left: int = 3

var drown: bool = false
var _bubble_timer: float

@onready var detector: ShapeCast2D = $Attack
@onready var vision: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

signal run_out

func _ready() -> void:
	await get_tree().physics_frame
	if belongs_to == Data.PROJECTILE_BELONGS.ENEMY:
		# Delete projectile if shot by enemy off-screen
		if !vision.is_on_screen():
			queue_free()
		# Delete projectile if shot by enemy from the top
		elif !Thunder.view.screen_top(global_position, 32, true):
			queue_free()
	# Delete projectile shot by player off-screen if it's there for too long
	elif !vision.is_on_screen():
		await get_tree().create_timer(3.0, false).timeout
		if is_inside_tree() && !vision.is_on_screen():
			queue_free()


func _physics_process(delta: float) -> void:
	super(delta)
	if drown:
		_bubble_timer += delta
		speed = Vector2(0, 75)
		if _bubble_timer > 0.18:
			_bubble_timer = 0
			var bubble = BUBBLE.instantiate()
			bubble.transform = global_transform
			Scenes.current_scene.add_child(bubble)


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
		collision_mask = 128
		return


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 320):
			queue_free()
		return
	Data.values.score += 200
	ScoreText.new(str(200), self)
	queue_free()
