extends Projectile

const explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
const BUBBLE = preload("res://engine/objects/effects/bubble/bubble.tscn")
@export var jumping_speed: float = -450.0
@export var bounces_left: int = 3

var drown: bool = false
var _bubble_timer: float

@onready var detector: ShapeCast2D = $Attack

signal run_out

func _ready() -> void:
	offscreen_handler(3.0)
	super()


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
	
	process_bumping_blocks()
	
	turn_x()
	
	if !ceiling: jump(jumping_speed)
	else: vel_set_y(0)
	
	bounces_left -= 1
	
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform().call_method(func(node):
		node.position.y += 12
	)
	
	if bounces_left == 0:
		run_out.emit()
		collision_layer = 0
		collision_mask = 128


func process_bumping_blocks() -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.collision_mask = collision_mask
	query.motion = Vector2(clamp(speed_previous.x, -1, 1), clamp(speed_previous.y, -1, 1)).rotated(global_rotation)
	
	for i in get_shape_owners():
		query.transform = (shape_owner_get_owner(i) as Node2D).global_transform
		for j in shape_owner_get_shape_count(i):
			query.shape = shape_owner_get_shape(i, j)
			
			var cldata: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query)
			
			for k in cldata:
				var l: Object = k.get(&"collider", null)
				var id: int = k.get(&"collider_id", 0)
				
				if l is StaticBumpingBlock:
					if l.has_method(&"got_bumped"):
						l.got_bumped.call_deferred(self)
					elif l.has_method(&"bricks_break"):
						l.bricks_break.call_deferred()


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 320):
			queue_free()
		return
	Data.values.score += 200
	ScoreText.new(str(200), self)
	queue_free()
