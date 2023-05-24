extends CharacterBody2D
class_name CorrectedCharacterBody2D

## A kind of [CharacterBody2D] that walks with correction when moving over through 32*32 tile gap

@export_group("Correction")
## Defines the amount of the vertical correction when moving over through 32*32 tile gap
@export var vertical_correction_amount: int = 10

## Defines the amount of the vertical correction when the body collide the corner of block
@export var horizontal_correction_amount: int = 5

## Should we automatically correct the collision?
@export var correct_collision: bool = true

func _ready() -> void:
	if Engine.is_editor_hint(): return
	_correct_collision()

func _correct_collision() -> void:
	if !correct_collision: return
	
	var collision = Thunder.get_child_by_class_name(self, 'CollisionShape2D')
	if collision: collision.global_position.y -= 1

## Run [method move_and_slide] with corrections
func move_and_slide_corrected() -> bool:
	vertical_correction(vertical_correction_amount)
	horizontal_correction(horizontal_correction_amount)
	return move_and_slide()

## Process of horizontal correction
func horizontal_correction(amount: int) -> void:
	if velocity.y >= 0: return
	
	var delta = get_physics_process_delta_time()
	var collide = move_and_collide(Vector2(0, velocity.y * delta).rotated(global_rotation), true)
	
	if !collide: return
	if Thunder.get_or_null(collide.get_collider(), "visible") == false: return
	
	var normal = collide.get_normal().rotated(-global_rotation)
	if abs(normal.x) >= 0.4: return
	
	for i in range(1, amount + 1):
		for j in [-1.0, 1.0]:
			if !test_move(
				global_transform.translated(Vector2(i * j, 0)),
				Vector2(0, velocity.y * delta).rotated(global_rotation)
			):
				translate(Vector2(i * j, 0).rotated(global_rotation))
				if velocity.x * j < 0: velocity.x = 0
				return

## Process of vertical correction
# Tile gap runover
func vertical_correction(amount: int) -> void:
	if is_on_floor(): return
	if velocity.y <= 0 or abs(velocity.x) <= 1: return
	
	var delta = get_physics_process_delta_time()
	var collide = move_and_collide(Vector2(velocity.x * delta, 0).rotated(global_rotation), true)
	
	if !collide: return
	if Thunder.get_or_null(collide.get_collider(), "visible") == false: return
	
	var normal = collide.get_normal().rotated(-global_rotation)
	if not abs(normal.x) == 1: return
	if abs(normal.y) >= 0.1: return
	
	for i in range(1, amount + 1):
		for j in [-1.0, 0]:
			if !test_move(
				global_transform.translated(Vector2(0, i * j)),
				Vector2(velocity.x * delta, 0).rotated(global_rotation)
			):
				translate(Vector2(0, i * j).rotated(global_rotation))
				if velocity.y * j < 0: velocity.y = 0
				return
