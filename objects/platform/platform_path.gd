extends PathFollow2D

@export_category("Platform")
@export_group("Settings")
@export_subgroup("Touching","touching_")
@export var touching_players_enabled:bool = true
@export var touching_non_players_enabled:bool
@export var touching_player_touched_movement:bool # Needs touching_players_enabled = true
@export_group("Physics")
@export var speed: float = 50.0
@export_subgroup("Smooth","smooth_")
@export var smooth_turning_length: float = 8.0
@export var smooth_turning_duration_fixer: float = 0.105
@export var smooth_points:PackedInt32Array
@export_subgroup("Falling","falling_")
@export var falling_direction: Vector2 = Vector2.DOWN
@export var falling_acceleration: float
@export_group("Extension")
@export var custom_vars: Dictionary
@export var custom_script: GDScript

var on_path:bool = true

var smooth_speed: float
var smooth_duration:float
var smooth_next_points:PackedVector2Array
var smooth_on_continue_point:bool
var smooth_step:int

var players_standing:Array[Node2D]
var non_players_standing:Array[Node2D]
var players_have_stood:bool
var non_players_have_stood:bool

var linear_velocity:Vector2

@onready var custom_script_instance: ByNodeScript = ByNodeScript.activate_script(custom_script,self,custom_vars)
@onready var block: AnimatableBody2D = $Block
@onready var surface: Area2D = $Block/Surface

@onready var on_moving: bool = !touching_player_touched_movement

@onready var curve: Curve2D = (
	func() -> Curve2D:
		if !get_parent() is Path2D: return null
		return get_parent().curve
).call()
@onready var max_progress: float = (
	func() -> float:
		var max_length: float
		var current: float = progress_ratio
		progress_ratio = 1.0
		max_length = progress
		progress_ratio = current
		return max_length
).call()


func _ready() -> void:
	if smooth_turning_length > 0: _sign_up_points()
	
	surface.body_entered.connect(
		func(body: Node2D) -> void:
			body = body as CharacterBody2D
			if !body: return
			if !body.is_on_floor(): return
			if body is Player && !body in players_standing:
				players_standing.append(body)
				players_have_stood = true
				on_moving = true
			elif !body is Player && !body in non_players_standing:
				non_players_standing.append(body)
				non_players_have_stood = true
	)

func _physics_process(delta: float) -> void:
	if !on_moving: return
	
	var pregpos:Vector2 = global_position
	_on_path_movement_process(delta)
	_non_path_movement_process(delta)
	linear_velocity = global_position - pregpos
	
	if block.sync_to_physics: block.global_position = block.global_position


func _on_path_movement_process(delta: float) -> void:
	if !curve || !on_path: return
	
	progress += speed * delta
	
	# Moving
	if smooth_turning_length > 0: _smooth_movement(delta)
	else: _sharp_movement()
	
	# Emit Falling
	if players_have_stood && falling_acceleration > 0:
		on_path = false

func _non_path_movement_process(delta: float) -> void:
	if on_path: return
	
	# Falling
	if players_have_stood && falling_acceleration > 0:
		linear_velocity += falling_direction.normalized() * falling_acceleration * delta
	
	global_position += linear_velocity


func _sharp_movement() -> void:
	if !curve: return
	if progress_ratio <= 0 || progress_ratio >= 1: speed *= -1

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
			
			if (speed > 0 && progress >= end - smooth_turning_length) || (speed < 0 && progress <= start + smooth_turning_length):
				smooth_speed = speed
				smooth_duration = (2 * smooth_turning_length / abs(smooth_speed)) + smooth_turning_duration_fixer
				smooth_step = 1
		1:
			var tw:Tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_trans(Tween.TRANS_SINE)
			tw.tween_property(self, "speed", 0, smooth_duration).set_ease(Tween.EASE_OUT)
			tw.tween_property(self, "speed", smooth_speed if smooth_on_continue_point else -smooth_speed, smooth_duration).set_ease(Tween.EASE_IN)
			tw.tween_callback(
				func() -> void: 
					if smooth_on_continue_point: smooth_next_points.remove_at(0)
					else: _sign_up_points()
					smooth_step = 0
			)
			smooth_step = 2


func _sign_up_points() -> void:
	for i in smooth_points: smooth_next_points.append(curve.get_point_position(i))
	if speed < 0: smooth_next_points.reverse()
