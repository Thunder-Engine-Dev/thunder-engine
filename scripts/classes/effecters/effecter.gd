extends RefCounted
class_name Effect

const TRAIL: PackedScene = preload("res://engine/objects/effects/trail/trail.tscn")


## Reusable settings for [method emit_trail]. Emission never modifies this object.
class TrailSettings extends RefCounted:
	## Overrides the sprite's current texture/frame. Null uses the sprite image.
	var texture: Texture2D
	var fade_out_strength: float = 0.05
	var lifetime: float = 1.0
	## Z index relative to the scene receiving the effect, not to the source sprite.
	var z_index: int = 0
	var material: Material
	var texture_filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_PARENT_NODE


## Emits one immediately visible image of a Sprite2D or AnimatedSprite2D.
## Capture [param previous_global_position] before moving the sprite in physics.
## Rotation, scale and the drawing pose are taken from the current sprite.
## Pass the current position for an effect that should not lag behind its source.
## With physics interpolation disabled, the current position is used automatically.
static func emit_trail(
	sprite: Node2D,
	previous_global_position: Vector2,
	settings: TrailSettings = null
) -> Sprite2D:
	if !is_instance_valid(sprite):
		return null
	var image: Texture2D
	var image_offset: Vector2
	var image_centered: bool
	var image_flip_h: bool
	var image_flip_v: bool
	if sprite is Sprite2D:
		image = sprite.texture
		image_offset = sprite.offset
		image_centered = sprite.centered
		image_flip_h = sprite.flip_h
		image_flip_v = sprite.flip_v
	elif sprite is AnimatedSprite2D:
		if sprite.sprite_frames != null:
			image = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		image_offset = sprite.offset
		image_centered = sprite.centered
		image_flip_h = sprite.flip_h
		image_flip_v = sprite.flip_v
	else:
		push_error("Effect.emit_trail requires a Sprite2D or AnimatedSprite2D.")
		return null
	var config: TrailSettings = settings if settings != null else TrailSettings.new()
	# Attach before applying world coordinates, including when the scene is transformed.
	return NodeCreator.prepare_2d(TRAIL, sprite).create_2d().call_method(
		func(effect: Sprite2D) -> void:
			effect.global_transform = sprite.global_transform
			effect.global_position = previous_global_position if sprite.is_physics_interpolated_and_enabled() else sprite.global_position
			effect.texture = config.texture if config.texture != null else image
			if sprite is Sprite2D && config.texture == null:
				effect.hframes = sprite.hframes
				effect.vframes = sprite.vframes
				effect.frame = sprite.frame
				effect.region_enabled = sprite.region_enabled
				effect.region_rect = sprite.region_rect
				effect.region_filter_clip_enabled = sprite.region_filter_clip_enabled
			effect.offset = image_offset
			effect.centered = image_centered
			effect.flip_h = image_flip_h
			effect.flip_v = image_flip_v
			effect.fade_out_strength = config.fade_out_strength
			effect.lifetime = config.lifetime
			effect.material = config.material
			effect.z_index = config.z_index
			effect.texture_filter = config.texture_filter
			# WARNING: If your game crashes here, go download a proper Godot build:
			# https://nx.wtf/s/aVtZ?path=Software%2FGodot-TE
			effect.snap_2d_transforms_mode = CanvasItem.SNAP_2D_TRANSFORMS_MODE_CANVAS
			effect.add_to_group(&"Trail")
	).get_node() as Sprite2D


## @deprecated: Use [method emit_trail] with a sprite and its pre-movement position.
## Retains the positional arguments and delayed visibility for compatibility.
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
	z_index: int = 0,
	interpolation_support: bool = true,
	texture_filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_PARENT_NODE
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
			tra.texture_filter = texture_filter
			# WARNING: If your game crashes here, go download a proper Godot build:
			# https://nx.wtf/s/aVtZ?path=Software%2FGodot-TE
			tra.snap_2d_transforms_mode = CanvasItem.SNAP_2D_TRANSFORMS_MODE_CANVAS
			tra.add_to_group(&"Trail")
			
			if interpolation_support:
				tra.self_modulate.a = 0
				await Thunder.get_tree().physics_frame
				if is_instance_valid(tra) && tra.is_inside_tree():
					tra.self_modulate.a = 1
	).create_2d().get_node() as Sprite2D
	
	return effect_node


static func flash(on: CanvasItem, duration: float, interval: float = 0.06, pause_mode = Tween.TWEEN_PAUSE_BOUND, self_modulate: bool = false, to: float = 1.0) -> Tween:
	if !on:
		return null
	var alpha: float = to
	var modulate_path: NodePath = ^"modulate:a" if !self_modulate else ^"self_modulate:a"
	var tw: Tween = on.create_tween().set_loops(int(ceilf(duration / interval))).set_pause_mode(pause_mode)
	tw.tween_property(on, modulate_path, 0, interval / 2)
	tw.tween_property(on, modulate_path, alpha, interval / 2)
	tw.tween_callback(
		func() -> void:
			if tw.get_loops_left() <= 0:
				if !self_modulate:
					on.modulate.a = alpha
				else:
					on.self_modulate.a = alpha
	)
	return tw
