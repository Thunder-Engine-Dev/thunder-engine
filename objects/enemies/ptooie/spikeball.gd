extends GravityBody2D

signal going_up
signal going_down
signal got_killed

@export var offset: Vector2 = Vector2(0, -56)
@export_category("References")
@export var sprite: NodePath

var active: bool = true
var dir: int
var counter: float
var target_pos: float
var is_blowing: bool:
	set(new):
		if is_blowing == new: return
		if new:
			going_up.emit()
		else:
			going_down.emit()
		is_blowing = new

@onready var sprite_node: Node2D = get_node_or_null(sprite)
@onready var blows: int


func _ready() -> void:
	if Engine.is_editor_hint(): return
	super()
	


func _physics_process(delta: float) -> void:
	motion_process(delta, false)
	sprite_node.rotation_degrees += 10 * Thunder.get_delta(delta)
	if !active: return
	
	blows = floor(counter / (PI * 2))
	if blows < 2:
		counter += delta * 4.5
		target_pos = -64 + offset.y
		position.y = cos(counter) * 64 + target_pos
	else:
		counter += delta * 3.5
		target_pos = -128 + offset.y
		if blows > 2:
			counter = 0
		position.y = cos(counter) * 128 + target_pos
	is_blowing = position.y > target_pos
	motion_process(delta)

func independence() -> void:
	active = false
	reparent(Scenes.current_scene, true)
	reset_physics_interpolation()
	gravity_scale = 0.5
	if blows < 2:
		speed = Vector2(0, sin(counter) * -256).rotated(global_rotation)
	else:
		speed = Vector2(0, sin(counter) * -512).rotated(global_rotation)
	get_tree().create_timer(3.0, false).timeout.connect(queue_free)
