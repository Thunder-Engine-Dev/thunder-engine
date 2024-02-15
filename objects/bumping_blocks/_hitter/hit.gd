extends "res://engine/objects/projectiles/projectile_attack.gd"

@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var dummy_speed: float = 100


func _enter_tree() -> void:
	velocity = Vector2(dummy_speed * [-1, 1].pick_random(), 0)


func _on_killed(what: Node, result: Dictionary) -> void:
	if !result.result: return
	if !&"owner" in what: return
	special_tags.clear()
	special_tags.append(
		&"attacked_from_right" if \
			Thunder.Math.look_at(global_position, what.owner.global_position, global_transform) > 0 else \
		&"attacked_from_left"
	)
