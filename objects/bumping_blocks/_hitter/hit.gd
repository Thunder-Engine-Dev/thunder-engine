extends "res://engine/objects/projectiles/projectile_attack.gd"


func _on_killed(what: Node, result: Dictionary) -> void:
	if !result.result: return
	if !&"owner" in what: return
	special_tags.clear()
	special_tags.append(
		&"attacked_from_right" if \
			global_position > what.owner.global_position else \
		&"attacked_from_left"
	)
