extends Node2D

var lava_objects: Array[Sprite2D]
var lava_velocity: Array[float]
var phases: Array[float]

var block_logic: bool = true

func _ready() -> void:
	$Area2D.area_got_in_lava_at.connect(_start_splash_seq, CONNECT_ONE_SHOT)
	for i in get_children():
		if i is Sprite2D:
			lava_objects.append(i)
	lava_velocity.resize(len(lava_objects))
	phases.resize(len(lava_objects))
	lava_velocity.fill(0.0)
	phases.fill(0.0)


func _start_splash_seq(pos: Vector2) -> void:
	block_logic = false
	for i in len(lava_objects):
		var lava: Sprite2D = lava_objects[i]
		var _pos: Vector2 = pos
		_pos.y = lava.global_position.y
		if lava.get_rect().has_point(lava.to_local(_pos)):
			_set_lava_velocities(i)
			return


func _set_lava_velocities(i: int) -> void: # 14
	var vel := 20.0
	lava_velocity[i] = vel
	var li: int = i - 1 # 13
	var ri: int = i + 1 # 15
	while vel > 0:
		await get_tree().create_timer(0.1, false).timeout
		if li >= 0:
			lava_velocity[li] = vel
			li -= 1 # 12 => 12 >= 0 => true
		if ri < lava_objects.size(): # 15 < 16
			lava_velocity[ri] = vel
			ri += 1 # 16 => 16 < 16 => false
		vel -= 4


func _physics_process(delta: float) -> void:
	if block_logic: return
	for i in len(lava_velocity):
		var vel: float = lava_velocity[i]
		if vel > 0.0:
			phases[i] += 5 * 50 * delta
			lava_objects[i].position.y = vel * sin(phases[i] / 50.0)
			lava_velocity[i] -= 0.1 * Thunder.get_delta(delta)

