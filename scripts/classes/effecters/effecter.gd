extends RefCounted
class_name Effect

const TRAIL: PackedScene = preload("res://engine/objects/effects/trail/trail.tscn")


static func trail(
	on: Node2D,
	texture: Texture2D = null,
	offset: Vector2 = Vector2.ZERO,
	flip_h: bool = false,
	flip_v: bool = false,
	centered: bool = true,
	fade_out_strength: float = 0.05,
	duration: float = 1.0,
	material: Material = null,
	z_index: int = 0
) -> Sprite2D:
	if !on:
		return null
	
	var effect_node = NodeCreator.prepare_2d(TRAIL, on).bind_global_transform().call_method(
		func(tra: Sprite2D) -> void:
			tra.offset = offset
			tra.texture = texture
			tra.flip_h = flip_h
			tra.flip_v = flip_v
			tra.centered = centered
			tra.fade_out_strength = fade_out_strength
			tra.lifetime = duration
			tra.material = material
			tra.z_index = on.z_index + z_index
			tra.add_to_group(&"Trail")
	).create_2d().get_node() as Sprite2D
	
	return effect_node


static func flash(on: CanvasItem, duration: float, interval: float = 0.06) -> void:
	if !on:
		return
	var alpha: float = on.modulate.a
	var tw: Tween = on.create_tween().set_loops(int(ceilf(duration / interval)))
	tw.tween_property(on, "modulate:a", 0, interval / 2)
	tw.tween_property(on, "modulate:a", alpha, interval / 2)
	tw.tween_callback(
		func() -> void:
			if tw.get_loops_left() <= 0:
				on.modulate.a = alpha
	)
