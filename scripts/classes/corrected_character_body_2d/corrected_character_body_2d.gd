extends CharacterBody2D
class_name CorrectedCharacterBody2D

@export var vertical_correction_amount: int = 10
@export var horizontal_correction_amount: int = 5

func move_and_slide_corrected() -> bool:
	vertical_correction(vertical_correction_amount)
	horizontal_correction(horizontal_correction_amount)
	return move_and_slide()

func horizontal_correction(amount: int) -> void:
	var delta = get_physics_process_delta_time()
	var collide = move_and_collide(Vector2(0, velocity.y * delta).rotated(rotation), true, true, true)
	
	if !collide: return
	if velocity.y >= 0: return
	if Thunder.get_or_null(collide.get_collider(), "visible") == false: return
	
	for i in range(1, amount + 1):
		for j in [-1.0, 1.0]:
			if !test_move(
				global_transform.translated(Vector2(i * j, 0)),
				Vector2(0, velocity.y * delta).rotated(rotation)
			):
				translate(Vector2(i * j, 0).rotated(rotation))
				return

# Tile gap runover
func vertical_correction(amount: int) -> void:
	var delta = get_physics_process_delta_time()
	var collide = move_and_collide(Vector2(velocity.x * delta, 0).rotated(rotation), true, true, true)
	
	if !collide: return
	if velocity.y <= 0: return
	if Thunder.get_or_null(collide.get_collider(), "visible") == false: return
	if !velocity.x: return
	
	for i in range(1, amount + 1):
		for j in [-1.0, 0]:
			var normal = collide.get_normal().rotated(-rotation)

			if !test_move(
				global_transform.translated(Vector2(0, i * j)),
				Vector2(velocity.x * delta, 0).rotated(rotation)
			) && !is_on_floor() && (normal.x == -1 || normal.x == 1) && abs(normal.y) < 0.1:
				translate(Vector2(0, i * j).rotated(rotation))
				if velocity.y * j < 0: velocity.y = 0
				return
