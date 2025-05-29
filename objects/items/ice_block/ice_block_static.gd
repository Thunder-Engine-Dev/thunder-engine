extends StaticBody2D

const ICE_DEBRIS = preload("res://engine/objects/effects/brick_debris/ice_debris.tscn")

## Speed of ice debris
@export_range(0, 9999, 0.1, "or_greater", "hide_slider", "suffix:px/s") var debris_speed: float = 6
@export_group("Sounds", "sound_")
## Sound of ice breaking normally.
@export var sound_breaking: AudioStream = preload("res://engine/objects/items/ice_block/sfx/ice_break.mp3")
## Sound of ice breaking heavily.
@export var sound_breaking_heavily: AudioStream = preload("res://engine/objects/items/ice_block/sfx/ice_break_heavy.tres")

var contained_item: Node2D
var contained_item_sprite: Node2D
var contained_item_enemy_killed: Node
var unfreeze_offset: Vector2

var _is_inside_tree: bool = false

@onready var _sprite: NinePatchRect = $SpriteNP
@onready var _collision_shapes: Array[CollisionShape2D] = [$CollisionShape2D, $Body/Collision]
@onready var _visible_on_screen: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D

func _ready() -> void:
	_is_inside_tree = true
	# Removes the contained item when the current scene gets changed to prevent memory leak
	get_tree().node_removed.connect(func(node: Node) -> void:
		if node == Scenes.current_scene && is_instance_valid(contained_item):
			contained_item.queue_free()
	)

## Draws the sprite for the ice
func draw_sprite(drawn_sprite: Node2D = contained_item_sprite, offset: Vector2 = Vector2.ZERO) -> void:
	if !is_instance_valid(drawn_sprite):
		return
	
	if !is_instance_valid(contained_item_sprite):
		contained_item_sprite = drawn_sprite
		add_child.call_deferred(contained_item_sprite)
	
	drawn_sprite.position = offset
	drawn_sprite.modulate.a = 0.25
	
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	
	drawn_sprite.material = mat
	drawn_sprite.process_mode = Node.PROCESS_MODE_DISABLED
	
	var size := _get_in_ice_sprite_size(drawn_sprite)
	_sprite.size = size
	_sprite.pivot_offset = size / 2
	_sprite.position = -_sprite.pivot_offset
	
	var rect := _sprite.get_rect()
	for i in _collision_shapes:
		if i.shape is RectangleShape2D:
			i.shape = i.shape.duplicate(true)
			(i.shape as RectangleShape2D).size = rect.size
		if i.shape is RectangleShape2D:
			i.shape = i.shape


func break_ice(heavy: bool = false, sound_heavily: bool = false) -> void:
	if process_mode == PROCESS_MODE_DISABLED:
		return
	
	if is_instance_valid(contained_item):
		(func():
			add_sibling(contained_item)
			contained_item.global_transform = global_transform
			if is_instance_valid(contained_item_sprite):
				contained_item.position += contained_item_sprite.position
			
			if !heavy && is_instance_valid(contained_item_enemy_killed):
				contained_item.set_deferred(&"global_transform", global_transform)
			elif contained_item.is_ancestor_of(contained_item_enemy_killed):
				contained_item_enemy_killed.got_killed(&"self")
			else:
				contained_item.queue_free()
			
			contained_item.set_deferred(&"position", contained_item.position + unfreeze_offset)
			contained_item.reset_physics_interpolation.call_deferred()
		).call_deferred()
	
	Audio.play_sound(sound_breaking_heavily if heavy else sound_breaking, self)
	
	if _visible_on_screen.is_on_screen():
		var rect := _sprite.get_rect().size
		var maximum_debris := int(roundf(_sprite.get_rect().get_area() / 170.67))
		var angle_unit := TAU / maximum_debris
		
		var get_ellipse_point: Callable = func(angle: float) -> Vector2:
			return Vector2(rect.x * cos(angle), rect.y * sin(angle))
		
		for i in maximum_debris:
			var angle := wrapf(angle_unit * i, -PI, PI) - angle_unit / 2
			var debris := NodeCreator.prepare_2d(ICE_DEBRIS, self).create_2d().get_node()
			debris.global_position = global_position + get_ellipse_point.call(angle)
			debris.velocity = debris_speed * Vector2.RIGHT.rotated(angle)
			debris.reset_physics_interpolation()
	
	queue_free()

func _get_in_ice_sprite_size(drawn_sprite: Node2D) -> Vector2:
	var size: Array[Vector2] = [Vector2.ONE * 32]
	
	if drawn_sprite is Sprite2D:
		if drawn_sprite.texture:
			size.append(drawn_sprite.texture.get_size())
	elif drawn_sprite is AnimatedSprite2D:
		if drawn_sprite.sprite_frames:
			var tex: Texture2D = drawn_sprite.sprite_frames.get_frame_texture(drawn_sprite.animation, drawn_sprite.frame)
			if tex:
				size.append(tex.get_size())
	
	size.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return absf(a.x * a.y) > absf(b.x * b.y)
	)
	
	return size[0]
