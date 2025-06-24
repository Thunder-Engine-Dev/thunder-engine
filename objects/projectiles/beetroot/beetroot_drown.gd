extends Node

func in_water() -> void:
	var beet = $".."
	beet.run_out.emit()
	beet.bounces_left = 0
	beet.collision_mask = 128
	beet.drown = true
	beet.speed.x = 0
	if has_meta(&"uid"):
		var _meta = get_meta(&"uid")
		if is_in_group("bul" + _meta):
			remove_from_group("bul" + _meta)
			add_to_group("bul_extra" + _meta)

func out_of_water() -> void:
	var beet = $".."
	beet.drown = false
