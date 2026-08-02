extends CharacterBody2D
class_name CorrectedCharacterBody2D

signal corrected_to_floor
signal corrected_to_floor_and_stopped
signal corrected_to_wall
signal corrected_to_wall_and_stopped

## A kind of [CharacterBody2D] that walks with correction when moving over through 32*32 tile gap

@export_group("Correction")
## Defines the amount of the vertical correction when moving over through 32*32 tile gap
@export var vertical_correction_amount: int = 10
## Defines the amount of the vertical correction when the body collide the corner of block
@export var horizontal_correction_amount: int = 5

## Should we automatically correct the collision?
@export var correct_collision: bool = true

## Apply subtick checks if the body's Y velocity is greater than 250.[br]
## The faster the body, the more times collisions will be checked during a single physics tick.[br]
## Set to 1 to disable subtick correction (legacy method).
@export_range(1, 16) var subtick_max_vertical_corrections_amount: int = 4

## Apply subtick checks if the body's X velocity is greater than 250.[br]
## The faster the body, the more times collisions will be checked during a single physics tick.[br]
## Set to 1 to disable subtick correction (legacy method).
@export_range(1, 16) var subtick_max_horizontal_corrections_amount: int = 4


func _ready() -> void:
	if Engine.is_editor_hint(): return
	_correct_collision()

func _correct_collision() -> void:
	if !correct_collision: return
	
	# The logic for correcting the collision position has been removed,
	# however some other stuff may appear here, so the function remains here
	# without currently doing any actions.
	pass

## Run [method move_and_slide] with corrections
func move_and_slide_corrected() -> bool:
	vertical_correction(vertical_correction_amount)
	horizontal_correction(horizontal_correction_amount)
	return move_and_slide()

## [member velocity] is world-space; correction logic uses body-local axes.
func _get_local_velocity() -> Vector2:
	return velocity.rotated(-global_rotation)

func _set_local_velocity(local_velocity: Vector2) -> void:
	velocity = local_velocity.rotated(global_rotation)

## Process of horizontal correction
func horizontal_correction(amount: int) -> void:
	var local_velocity := _get_local_velocity()
	if local_velocity.y >= 0: return
	
	var actual_delta := get_physics_process_delta_time()
	var subtick_check_loop_amount: int = 1
	subtick_check_loop_amount += min(
		floori(abs(local_velocity.x) / 250.0),
		subtick_max_horizontal_corrections_amount - 1
	)
	
	for subtick in subtick_check_loop_amount:
		var delta := (actual_delta / float(subtick_check_loop_amount)) * float(subtick + 1)
		var collide := move_and_collide(Vector2(0, local_velocity.y * delta).rotated(global_rotation), true)
		
		if !collide: continue
		if Thunder.get_or_null(collide.get_collider(), "visible") == false: continue
		if Thunder.get_or_null(collide.get_collider(), "_ignore_colliding_body_correction") == true: continue
		
		var normal = collide.get_normal().rotated(-global_rotation)
		if abs(normal.x) >= 0.4: continue
		
		for i in range(1, amount + 1):
			for j in [-1.0, 1.0]:
				if !test_move(
					global_transform.translated_local(Vector2(i * j, 0)),
					Vector2(0, local_velocity.y * delta).rotated(global_rotation)
				):
					translate(Vector2(i * j, 0).rotated(global_rotation))
					corrected_to_wall.emit()
					if local_velocity.x * j < 0:
						local_velocity.x = 0
						_set_local_velocity(local_velocity)
						corrected_to_wall_and_stopped.emit()
						if has_signal(&"collided_wall"):
							emit_signal(&"collided")
							emit_signal(&"collided_wall")
					return
 
## Process of vertical correction (Tile gap runover)
func vertical_correction(amount: int) -> void:
	if is_on_floor(): return
	var local_velocity := _get_local_velocity()
	if local_velocity.y <= 0 or abs(local_velocity.x) <= 1: return
	
	# 4.5: detailized the condition to prevent the player from being stucked at the corner to avoid potential bugs
	const TEST_MARGIN := 0.1
	var n := Vector2.UP.rotated(global_rotation)
	if is_on_wall() && velocity.normalized().dot(n) < 0.0 && test_move(global_transform, -velocity.project(n) * TEST_MARGIN):
		return
	
	var actual_delta := get_physics_process_delta_time()
	var subtick_check_loop_amount: int = 1
	subtick_check_loop_amount += min(
		floori(local_velocity.y / 250.0),
		subtick_max_vertical_corrections_amount - 1
	)
	for subtick in subtick_check_loop_amount:
		var delta := (actual_delta / float(subtick_check_loop_amount)) * float(subtick + 1)
		var motion := Vector2(local_velocity.x * delta, local_velocity.y * delta).rotated(global_rotation)
		var collide := move_and_collide(motion, true, 0.08, false)
		
		if !collide: continue
		if Thunder.get_or_null(collide.get_collider(), "visible") == false: continue
		if Thunder.get_or_null(collide.get_collider(), "_ignore_colliding_body_correction") == true: continue
		
		var normal: Vector2 = collide.get_normal().rotated(-global_rotation)
		if not abs(normal.x) == 1: continue
		if abs(normal.y) >= 0.1: continue
		
		for i in range(1, amount * 2 + 1):
			@warning_ignore("integer_division")
			var _translation: int = -i / 2
			if _translation == 0: continue
			if !test_move(
				global_transform.translated_local(Vector2(0, _translation)),
				motion,
			):
				translate(Vector2(0, _translation + local_velocity.y * delta).rotated(global_rotation))
				corrected_to_floor.emit()
				if local_velocity.y > 0:
					local_velocity.y = 0
					_set_local_velocity(local_velocity)
					corrected_to_floor_and_stopped.emit()
					if has_signal(&"collided_floor"):
						emit_signal(&"collided")
						emit_signal(&"collided_floor")
				return
