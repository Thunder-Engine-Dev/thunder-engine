extends PathFollow2D

@export_category("Platform")
@export_group("Settings")
@export_subgroup("Touching","touching_")
@export var touching_players_enabled:bool = true
@export var touching_non_players_enabled:bool
@export var touching_player_touched_movement:bool # Needs touching_players_enabled = true
@export_group("Physics")
@export var speed: float = 150.0
@export var loop_backwards: bool = true
@export var warp_objects_on_end: bool = true
@export var warping_edge_ignore_px: float = 8.0
@export_subgroup("Smooth","smooth_")
@export var smooth_enabled: bool = true
@export var smooth_turning_length: float = 64.0
@export var smooth_turning_duration_fixer: float = 0.105
@export var smooth_points:PackedInt32Array
@export_subgroup("Falling","falling_")
@export var falling_enabled: bool = false
@export var falling_direction: Vector2 = Vector2.DOWN
@export var falling_acceleration: float = 10.0
@export_group("Extension")
@export var custom_vars: Dictionary
@export var custom_script: GDScript
@export_group("References")
@export var sprite: NodePath

var on_path: bool = true

var smooth_speed: float
var smooth_duration: float
var smooth_next_points: PackedVector2Array
var smooth_on_continue_point: bool
var smooth_step: int

var players_standing: Array[Node2D]
var non_players_standing: Array[Node2D]
var players_have_stood: bool
var non_players_have_stood: bool

var linear_velocity: Vector2
var _path_falling_speed: float
#var _block_ready: bool = false

@onready var custom_script_instance: ByNodeScript = ByNodeScript.activate_script(custom_script,self,custom_vars)
@onready var block: StaticBody2D = $Block
@onready var sprite_node: Node2D = get_node_or_null(sprite)

@onready var on_moving: bool = !touching_player_touched_movement

@onready var curve: Curve2D = (
	func() -> Curve2D:
		if !get_parent() is Path2D: return null
		return get_parent().curve
).call()
@onready var max_progress: float = (
	func() -> float:
		if !curve: return 0.0
		var max_length: float
		var current: float = progress_ratio
		progress_ratio = 1.0
		max_length = progress
		progress_ratio = current
		return max_length
).call()
@onready var init_collision_layer: int = block.collision_layer

# Block movement of the platform in scripts
var _movement_blocked: bool = false

func _ready() -> void:
	#_detach_platform_block.call_deferred()
	if smooth_turning_length > 0: _sign_up_points()

func _physics_process(delta: float) -> void:
	#_fix_position()
	
	if !on_moving: return
	if get_child_count() == 0 && !is_instance_valid(block): return
	#if !_block_ready: return
	
	_on_path_movement_process(delta)
	_non_path_movement_process(delta)
	
	#if block is AnimatableBody2D && block.sync_to_physics: block.global_position = block.global_position


func _body_check(body: CharacterBody2D) -> void:
	if !body: return
	if !body.is_on_floor(): return
	if !body is Player && !body in non_players_standing:
		non_players_standing.append(body)
		non_players_have_stood = true


func _player_landed(player: Player) -> void:
	if !player in players_standing:
		players_standing.append(player)
	players_have_stood = true
	on_moving = true


func _on_path_movement_process(delta: float) -> void:
	if !on_path: return
	if _movement_blocked: return
	
	#var pos: Vector2 = global_position
	# Moving
	if players_have_stood && falling_acceleration != 0 && falling_enabled:
		linear_velocity += falling_direction.normalized() * _path_falling_speed * delta
		if curve:
			_path_falling_speed += falling_acceleration
		else:
			_path_falling_speed = falling_acceleration
	
	if curve:
		progress += speed * delta
		if loop:
			if warp_objects_on_end: return
			block.set_deferred(
				&"collision_layer", 0 if (
					progress > max_progress - warping_edge_ignore_px ||
					progress < warping_edge_ignore_px
				) else init_collision_layer
			)
			return
		if smooth_enabled && smooth_turning_length > 0: _smooth_movement(delta)
		else: _sharp_movement()
	
	if falling_acceleration != 0:
		global_position += linear_velocity * Thunder.get_delta(delta)
	
	#linear_velocity = (global_position - pos) / delta
	# Emit Falling
	#if on_path && players_have_stood && falling_acceleration > 0.0 && falling_enabled:
	#	on_path = false


func _non_path_movement_process(delta: float) -> void:
	if on_path: return
	if _movement_blocked: return
	
	# Falling
	if players_have_stood && falling_acceleration != 0 && falling_enabled:
		linear_velocity += falling_direction.normalized() * falling_acceleration * delta
	
	global_position += linear_velocity * Thunder.get_delta(delta)


func _sharp_movement() -> void:
	if !curve: return
	if loop_backwards && (progress_ratio <= 0 || progress_ratio >= 1): speed *= -1

func _smooth_movement(delta: float) -> void:
	if !curve: return
	
	smooth_on_continue_point = !smooth_next_points.is_empty()
	match smooth_step:
		0:
			var start:float = 0.0
			var end:float = max_progress
			var next_point_progress:float
			
			if smooth_on_continue_point: 
				next_point_progress = curve.get_closest_offset(smooth_next_points[0])
				if speed > 0: end = next_point_progress
				elif speed < 0: start = next_point_progress
			
			if (speed > 0.0 && progress >= end - smooth_turning_length) || (speed < 0.0 && progress <= start + smooth_turning_length):
				smooth_speed = speed
				smooth_duration = smooth_turning_length / abs(smooth_speed) + smooth_turning_duration_fixer
				smooth_step = 1
		1:
			var tw:Tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_trans(Tween.TRANS_SINE)
			tw.tween_property(self, "speed", 0, smooth_duration)
			tw.tween_property(self, "speed", smooth_speed if smooth_on_continue_point else -smooth_speed, smooth_duration)
			tw.tween_callback(
				func() -> void: 
					if smooth_on_continue_point: smooth_next_points.remove_at(0)
					else: _sign_up_points()
					smooth_step = 0
			)
			smooth_step = 2


func _sign_up_points() -> void:
	for i in smooth_points: smooth_next_points.append(curve.get_point_position(i))
	if speed < 0.0: smooth_next_points.reverse()


#var _par: Node
#func _find_parent_to_detach() -> void:
	#while _par is Path2D || _par == self:
		#_par = _par.get_parent()
		#if _par == get_tree().root:
			#_par = null
			#break
#
#
#func _detach_platform_block() -> void:
	#_par = block.get_parent()
	#_find_parent_to_detach()
	#if !_par:
		#printerr("Unable to find a parent of " + name)
		#return
	#block.reparent(_par)
	#Thunder.reorder_on_top_of(block, self)
	#_fix_position()
	#if modulate != Color.WHITE:
		#block.modulate = modulate
	#_block_ready = true

func _fix_position() -> void:
	if block.includes_path_follow: return
	var _set_pos: Vector2 = global_position.round()
	block.global_position = _set_pos

#func _exit_tree() -> void:
	#if !_block_ready: return
	#block.queue_free()
