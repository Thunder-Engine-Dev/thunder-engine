extends GeneralMovementBody2D

const ICE_DEBRIS = preload("res://engine/objects/effects/brick_debris/ice_debris.tscn")

## Delay to destroy the ice.
@export_range(0, 20, 0.1, "or_greater") var destroy_delay: float = 6
## Delay to flash before the ice is to be broken.
@export_range(0, 20, 0.1, "or_greater") var flash_pre_seconds: float = 1.5
## Speed at or over which the ice block will break when it hits the ground.
@export_range(0, 9999, 0.1, "or_greater", "hide_slider", "suffix:px/s") var breaking_speed: float = 300
## Speed of ice debris
@export_range(0, 9999, 0.1, "or_greater", "hide_slider", "suffix:px/s") var debris_speed: float = 6
## Sound of ice breaking normally.
@export var sound_breaking: AudioStream = preload("res://engine/objects/items/ice_block/sfx/ice_break.mp3")
## Sound of ice breaking heavily.
@export var sound_breaking_heavily: AudioStream = preload("res://engine/objects/items/ice_block/sfx/ice_break_heavily.mp3")

var contained_item: Node2D
var contained_item_sprite: Node2D
var contained_item_enemy_killed: Node

@onready var _sprite: NinePatchRect = $SpriteNP
@onready var _separate_up: CollisionShape2D = $SeparateUp
@onready var _separate_down: CollisionShape2D = $SeparateDown
@onready var _separate_left: CollisionShape2D = $SeparateLeft
@onready var _separate_right: CollisionShape2D = $SeparateRight
@onready var _timer_destroy: Timer = $TimerDestroy


func _ready() -> void:
	# Removes the contained item when the current scene gets changed to prevent memory leak
	get_tree().node_removed.connect(func(node: Node) -> void:
		if node == Scenes.current_scene && is_instance_valid(contained_item):
			contained_item.queue_free()
	)
	
	for i in 10:
		await get_tree().physics_frame
	
	_separate_up.queue_free()
	_separate_down.queue_free()
	_separate_left.queue_free()
	_separate_right.queue_free()
	
	_timer_destroy.start(destroy_delay)
	_timer_destroy.timeout.connect(break_ice)
	
	if flash_pre_seconds < destroy_delay:
		const FLASH_INTERVAL := 0.08
		
		var alpha := modulate.a
		
		await get_tree().create_timer(destroy_delay - flash_pre_seconds, false).timeout
		_sprite.material = null
		
		var tw := create_tween().set_loops(int(ceilf(flash_pre_seconds / 0.1))).set_trans(Tween.TRANS_SINE)
		tw.tween_property(self, ^"modulate:a", 0.25, FLASH_INTERVAL)
		tw.tween_property(self, ^"modulate:a", alpha, FLASH_INTERVAL)
		
		tw.finished.connect(break_ice)


func _physics_process(delta: float) -> void:
	super(delta)
	if speed_previous.y > breaking_speed && is_on_floor():
		break_ice(true, true)


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
	
	var size: Vector2 = Vector2.ONE * 32
	if drawn_sprite is Sprite2D:
		if drawn_sprite.texture:
			size = drawn_sprite.texture.get_size()
	elif drawn_sprite is AnimatedSprite2D:
		if drawn_sprite.sprite_frames:
			var tex: Texture2D = drawn_sprite.sprite_frames.get_frame_texture(drawn_sprite.animation, drawn_sprite.frame)
			if tex:
				size = tex.get_size()
	
	drawn_sprite.process_mode = Node.PROCESS_MODE_DISABLED
	
	_sprite.size = size
	_sprite.pivot_offset = size / 2
	_sprite.position = -_sprite.pivot_offset
	
	var rect := _sprite.get_rect()
	_separate_up.position.y = rect.position.y
	_separate_down.position.y = rect.end.y
	_separate_left.position.x = rect.position.x
	_separate_right.position.x = rect.end.x


## Breaks the ice.[br]
## If [param heavy] is [code]true[/code], the object in the block will be destroyed.[br]
## [param sound_heavily] determines which type of sound will play on the ice's breaking.
func break_ice(heavy: bool = false, sound_heavily: bool = false) -> void:
	if !is_instance_valid(contained_item):
		return
	
	(func():
		add_sibling(contained_item)
		contained_item.global_transform = global_transform
		contained_item.position += contained_item_sprite.position
		contained_item.reset_physics_interpolation()
		
		if !heavy && is_instance_valid(contained_item_enemy_killed):
			contained_item.set_deferred(&"global_transform", global_transform)
		elif contained_item.is_ancestor_of(contained_item_enemy_killed):
			contained_item_enemy_killed.got_killed(&"suicide")
		else:
			contained_item.queue_free()
	).call_deferred()
	
	Audio.play_sound(sound_breaking_heavily if sound_heavily else sound_breaking, self)
	
	var rect := _sprite.get_rect().size
	var get_ellipse_point: Callable = func(angle: float) -> Vector2:
		return Vector2(rect.x * cos(angle), rect.y * sin(angle))
	var maximum_debris := int(roundf(_sprite.get_rect().get_area() / 170.67))
	var angle_unit := TAU / maximum_debris
	
	for i in maximum_debris:
		var angle := wrapf(angle_unit * i, -PI, PI) - angle_unit / 2
		var debris := NodeCreator.prepare_2d(ICE_DEBRIS, self).bind_global_transform(get_ellipse_point.call(angle)).create_2d().get_node()
		debris.velocity = debris_speed * Vector2.RIGHT.rotated(global_rotation + angle)
	
	queue_free()