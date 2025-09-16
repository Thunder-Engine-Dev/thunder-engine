extends GeneralMovementBody2D

##
##
##

##
signal grabbing_got_thrown(is_ungrab: bool)

##
const ICE_DEBRIS = preload("res://engine/objects/effects/brick_debris/ice_debris.tscn")
const PREMULT_MATERIAL = preload("res://engine/objects/items/ice_block/premultiplied_material.tres")

## If [code]true[/code], the ice block will keep affected by gravity till it is grabbed.
@export var ice_fallable: bool = true:
	set(value):
		ice_fallable = value
		
		if ice_fallable: return
		
		_gravity_scale = gravity_scale
		gravity_scale = 0.0
## Whether to destroy the ice after a delay.
@export var destroy_enabled: bool = false
## Delay to destroy the ice.
@export_range(0, 20, 0.1, "or_greater") var destroy_delay: float = 6
## Delay to flash before the ice is to be broken.
@export_range(0, 20, 0.1, "or_greater") var flash_pre_seconds: float = 1.5
## Enable breaking by speed
@export var break_by_speed: bool = false
## Speed at or over which the ice block will break when it hits the ground.
@export_range(0, 9999, 0.1, "or_greater", "hide_slider", "suffix:px/s") var breaking_speed: float = 450
## Speed of ice debris
@export_range(0, 9999, 0.1, "or_greater", "hide_slider", "suffix:px/s") var debris_speed: float = 6
@export var break_if_stuck: bool = true
@export_group("Push")
## If [code]true[/code], the block is pushable.
@export var pushable: bool = true
## Max speed of the ice block during Mario pushing it.
@export_range(0, 9999, 0.1, "or_greater", "hide_slider", "suffix:px/s") var pushing_max_speed: float = 300
## Acceleration of the ice block while Mario is pushing it.
@export_range(0, 99999, 0.1, "or_greater", "hide_slider", "suffix:px/s²") var pushing_acceleration: float = 250
## Deceleration of the ice block when moving.
@export_range(0, 99999, 0.1, "or_greater", "hide_slider", "suffix:px/s²") var deceleration: float = 250
@export_group("Sounds", "sound_")
## Sound of ice breaking normally.
@export var sound_breaking: AudioStream = preload("res://engine/objects/items/ice_block/sfx/ice_break.mp3")
## Sound of ice breaking heavily.
@export var sound_breaking_heavily: AudioStream = preload("res://engine/objects/items/ice_block/sfx/ice_break_heavy.tres")

var forced_heavy_break: bool
var contained_item: Node2D
var contained_item_sprite: Node2D
var contained_item_enemy_killed: Node
var unfreeze_offset: Vector2

var _is_inside_tree: bool = false
var _being_grabbed: bool

var _break_blocked: bool = false

@onready var _sprite: NinePatchRect = $SpriteNP
@onready var _collision_shapes: Array[CollisionShape2D] = [$CollisionShape2D, $Body/Collision] 
@onready var _attack: ShapeCast2D = $Attack
@onready var _timer_destroy: Timer = $TimerDestroy
@onready var _visible_on_screen: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D
@onready var _solid_checker: Area2D = $SolidChecker
#@onready var _body: Area2D = $Body
#@onready var _body_collision: CollisionShape2D = $Body/Collision

@onready var _gravity_scale: float = gravity_scale

func _ready() -> void:
	_is_inside_tree = true
	# Removes the contained item when the current scene gets changed to prevent memory leak
	get_tree().node_removed.connect(func(node: Node) -> void:
		if node == Scenes.current_scene && is_instance_valid(contained_item):
			contained_item.queue_free()
	)
	
	for i in 10:
		await get_tree().physics_frame
	
	if destroy_enabled:
		start_timedown()
		_timer_destroy.timeout.connect(break_ice)
		
		if flash_pre_seconds < destroy_delay:
			if _being_grabbed:
				return
			
			const FLASH_INTERVAL := 0.08
			
			var alpha := modulate.a
			
			await get_tree().create_timer(destroy_delay - flash_pre_seconds, false, true).timeout
			
			if _being_grabbed:
				return
			elif process_mode == PROCESS_MODE_DISABLED:
				return
			
			_sprite.material = null
			
			var tw := create_tween().set_loops(int(ceilf(flash_pre_seconds / 0.1))).set_trans(Tween.TRANS_SINE)
			tw.tween_property(self, ^"modulate:a", 0.25, FLASH_INTERVAL)
			tw.tween_property(self, ^"modulate:a", alpha, FLASH_INTERVAL)
			
			if _being_grabbed:
				tw.kill()
				modulate.a = alpha
				return
			else:
				tw.finished.connect(break_ice)
	
	grabbing_got_thrown.connect(
		func(_is_ungrab: bool) -> void:
			break_by_speed = true
	)


func _physics_process(delta: float) -> void:
	if _is_inside_tree:
		gravity_dir = get_gravity().normalized()
		if !gravity_dir.is_zero_approx():
			up_direction = -gravity_dir
	
	super(delta)
	
	if speed_previous.length_squared() > 200 ** 2:
		for i: int in get_slide_collision_count():
			var col := get_slide_collision(i)
			if !col:
				continue
			var collider := col.get_collider()
			if collider is StaticBumpingBlock && collider.has_method(&"bricks_break"):
				collider.bricks_break()
				break_ice(true, false)
	
	if !_break_blocked:
		if absf(speed_previous.x) > breaking_speed && is_on_wall() && break_by_speed:
			break_ice(true, false)
		if speed_previous.y < 0 && is_on_ceiling() && break_by_speed:
			break_ice(true, false)
		if speed_previous.y > breaking_speed && is_on_floor() && break_by_speed:
			break_ice(true, true)
	
	_attack.enabled = !is_zero_approx(velocity.length_squared())
	
	speed.x = move_toward(speed.x, 0, deceleration * delta)


## Draws the sprite for the ice
func draw_sprite(drawn_sprite: Node2D = contained_item_sprite, offset: Vector2 = Vector2.ZERO) -> void:
	if !is_instance_valid(drawn_sprite):
		return
	
	if !is_instance_valid(contained_item_sprite):
		contained_item_sprite = drawn_sprite
		add_child.call_deferred(contained_item_sprite)
	
	drawn_sprite.position = offset
	drawn_sprite.modulate.a = 0.25
	
	drawn_sprite.material = PREMULT_MATERIAL
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
	
	if _attack.shape is RectangleShape2D:
		_attack.shape = _attack.shape.duplicate(true)
		(_attack.shape as RectangleShape2D).size = rect.size
	
	if !break_if_stuck:
		return
	var _solid_checker_col = _solid_checker.get_child(0)
	if _solid_checker_col.shape is RectangleShape2D:
		_solid_checker_col.shape = _solid_checker_col.shape.duplicate(true)
		(_solid_checker_col.shape as RectangleShape2D).size = rect.size - Vector2(8, 8)

## Breaks the ice.[br]
## If [param heavy] is [code]true[/code], the object in the block will be destroyed.[br]
## [param sound_heavily] determines which type of sound will play on the ice's breaking.
func break_ice(heavy: bool = false, sound_heavily: bool = false) -> void:
	if process_mode == PROCESS_MODE_DISABLED:
		return
	
	if forced_heavy_break:
		heavy = true
		sound_heavily = true
	
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
	
	
	Audio.play_sound(sound_breaking_heavily if sound_heavily else sound_breaking, self)
	
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

## Starts the timedown of breaking the ice block.
func start_timedown(grabbed: bool = false) -> void:
	_timer_destroy.paused = false
	_timer_destroy.start(destroy_delay)
	
	if grabbed:
		_being_grabbed = false

## Pauses the timedown of breaking the ice block.
func pause_timedown(grabbed: bool = false) -> void:
	_timer_destroy.paused = true
	
	if grabbed:
		_being_grabbed = true


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

func _on_ungrabbed() -> void:
	_break_blocked = true
	print.call_deferred(_solid_checker.get_overlapping_bodies())
	if break_if_stuck && _solid_checker.get_overlapping_bodies().size() > 0:
		break_ice(true)
		return
	
	gravity_scale = _gravity_scale
	
	for i in 4:
		await get_tree().physics_frame

	_break_blocked = false
	
	if speed_previous.y < 250:
		break_by_speed = true
