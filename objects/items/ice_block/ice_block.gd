extends GeneralMovementBody2D

##
signal grabbing_got_thrown(is_ungrab: bool)

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
@export_range(0, 9999, 0.1, "or_greater", "hide_slider", "suffix:px/s") var breaking_speed: float = 700
## Speed of ice debris
@export_range(0, 9999, 0.1, "or_greater", "hide_slider", "suffix:px/s") var debris_speed: float = 6
@export var break_if_stuck: bool = true
## Deceleration of the ice block when moving.
@export_range(0, 99999, 0.1, "or_greater", "hide_slider", "suffix:px/s²") var deceleration: float = 250
@export_group("Sounds", "sound_")
## Sound of ice breaking normally.
@export var sound_breaking: AudioStream = preload("res://engine/objects/items/ice_block/sfx/ice_break.mp3")
## Sound of ice breaking heavily.
@export var sound_breaking_heavily: AudioStream = preload("res://engine/objects/items/ice_block/sfx/ice_break_heavy.tres")

var belongs_to := Data.PROJECTILE_BELONGS.PLAYER
var forced_heavy_break: bool
var contained_item: Node2D
var contained_item_sprite: Node2D
var contained_item_enemy_killed: Node
var unfreeze_offset: Vector2

var _is_inside_tree: bool = false
var _being_grabbed: bool
var _attack_active: bool = false
var _break_blocked: bool = false
var _restore_player_collision: bool = false
var _throw_collision_suppressed: bool = false
var _saved_collision_layer: int
var _saved_collision_mask: int
var _saved_animatable_collision_layer: int
var _saved_animatable_collision_mask: int
var _saved_body_collision_layer: int
var _saved_body_collision_mask: int
var _ungrab_speed: Vector2
var _geometry_stuck_pending: bool = false
var _powerup_collision_exceptions: Array[Powerup] = []

@onready var _sprite: NinePatchRect = $SpriteNP
@onready var _collision_shapes: Array[CollisionShape2D] = [$CollisionShape2D, $Body/Collision, $AnimatableBody2D/Collision]
@onready var _attack: ShapeCast2D = $Attack
@onready var _timer_destroy: Timer = $TimerDestroy
@onready var _visible_on_screen: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D
@warning_ignore("unused_private_class_variable")
@onready var _solid_checker: Area2D = $SolidChecker
@onready var _solid_checker_shape: CollisionShape2D = $SolidChecker/CollisionShape2D
@onready var _powerup_solid_checker_shape: CollisionShape2D = $PowerupSolidChecker/CollisionShape2D
@onready var _body_area: Area2D = $Body
@onready var _animatable_body: AnimatableBody2D = $AnimatableBody2D
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

const SOLID_CHECKER_MASK := 112
const POWERUP_SOLID_CHECKER_MASK := 4
const STUCK_GEOMETRY_DEPTH := 2.5
const STUCK_ESCAPE_DISTANCE := 4.0

@onready var _gravity_scale: float = gravity_scale

func _ready() -> void:
	_is_inside_tree = true
	_attack.enabled = false
	_attack.belongs_to = Data.PROJECTILE_BELONGS.PLAYER
	break_by_speed = false
	add_collision_exception_with(_animatable_body)
	_prepare_solid_checker_shape()
	_prepare_powerup_solid_checker_shape()
	
	get_tree().node_removed.connect(func(node: Node) -> void:
		if node == Scenes.current_scene && is_instance_valid(contained_item):
			contained_item.queue_free()
	)
	
	#for i in 10:
	await get_tree().physics_frame
	
	if destroy_enabled:
		start_timedown()
		_timer_destroy.timeout.connect(break_ice)
		
		_prepare_flashing_animation()
	
	grabbing_got_thrown.connect(
		func(_is_ungrab: bool) -> void:
			break_by_speed = true
	)


func _prepare_flashing_animation() -> void:
	if flash_pre_seconds >= destroy_delay:
		return
	if _being_grabbed:
		return
	
	const FLASH_INTERVAL := 0.05
	
	var alpha := modulate.a
	
	await get_tree().create_timer(destroy_delay - flash_pre_seconds, false, true).timeout
	
	if _being_grabbed:
		return
	elif process_mode == PROCESS_MODE_DISABLED:
		return
	
	#_sprite.material = null
	
	var tw := create_tween().set_loops(int(ceilf(flash_pre_seconds / (FLASH_INTERVAL * 2)))) \
		.set_trans(Tween.TRANS_SINE).set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tw.tween_property(self, ^"modulate:a", 0.1, FLASH_INTERVAL)
	tw.tween_property(self, ^"modulate:a", alpha, FLASH_INTERVAL)
	
	if _being_grabbed:
		tw.kill()
		modulate.a = alpha
		return
	else:
		tw.finished.connect(break_ice)


func _prepare_solid_checker_shape() -> void:
	var rect := _sprite.get_rect()
	if _solid_checker_shape.shape is RectangleShape2D:
		_solid_checker_shape.shape = _solid_checker_shape.shape.duplicate(true)
		(_solid_checker_shape.shape as RectangleShape2D).size = rect.size - Vector2(2, 2)


func _prepare_powerup_solid_checker_shape() -> void:
	var rect := _sprite.get_rect()
	if _powerup_solid_checker_shape.shape is RectangleShape2D:
		_powerup_solid_checker_shape.shape = _powerup_solid_checker_shape.shape.duplicate(true)
		(_powerup_solid_checker_shape.shape as RectangleShape2D).size = rect.size


func _physics_process(delta: float) -> void:
	if _is_inside_tree:
		gravity_dir = get_gravity().normalized()
		if !gravity_dir.is_zero_approx():
			up_direction = -gravity_dir
	
	super(delta)
	
	_animatable_body.global_position = global_position
	
	if speed_previous.length_squared() > 200 ** 2:
		for i: int in get_slide_collision_count():
			var col := get_slide_collision(i)
			if !col:
				continue
			var collider := col.get_collider()
			if collider is StaticBumpingBlock && collider.has_method(&"bricks_break"):
				collider.bricks_break()
				break_ice(true, true)
	
	if !_break_blocked && break_by_speed:
		if absf(speed_previous.x) > breaking_speed && is_on_wall():
			break_ice(true, true)
		if speed_previous.y < 0 && is_on_ceiling():
			break_ice(true, true)
		if speed_previous.y > breaking_speed && _has_solid_floor_collision():
			break_ice(true, true)
	
	_attack.enabled = _attack_active && !is_zero_approx(velocity.length_squared())
	
	speed.x = move_toward(speed.x, 0, deceleration * delta)
	
	# fix ice blocks accelerating speed and breaking randomly when standing on each other
	if is_on_floor() && velocity.y > 0:
		velocity.y = 1
	
	_update_item_floor_collision_layer()
	_try_break_if_geometry_stuck()
	_try_break_if_player_stuck_inside()
	if _restore_player_collision && is_on_floor():
		_register_powerup_collision_exceptions()
	_try_restore_player_collision()


func _update_item_floor_collision_layer() -> void:
	if _throw_collision_suppressed:
		return
	# Layer 7 is also used by powerups as floor; keep it for ice-ice when idle/falling vertically.
	var block_item_floor := _being_grabbed || _restore_player_collision \
			|| !is_zero_approx(speed.x)
	set_collision_layer_value(7, !block_item_floor)


func _has_solid_floor_collision() -> bool:
	if !is_on_floor():
		return false
	for i in get_slide_collision_count():
		var _collision: KinematicCollision2D = get_slide_collision(i)
		if !_collision:
			continue
		if _collision.get_normal().dot(up_direction) <= 0.5:
			continue
		var collider = _collision.get_collider()
		if collider is Player || (collider is CharacterBody2D && collider.get_script() != get_script()):
			return false
		return true
	return false


func _on_grab_initiated() -> void:
	pause_timedown(true)
	_attack_active = false
	_attack.enabled = false
	break_by_speed = false
	_restore_player_collision = false
	_geometry_stuck_pending = false
	_clear_powerup_collision_exceptions()


func _on_grabbed() -> void:
	_on_grab_initiated()


func _on_ungrabbed() -> void:
	gravity_scale = _gravity_scale
	_attack.belongs_to = Data.PROJECTILE_BELONGS.PLAYER
	_attack_active = true
	break_by_speed = true
	_being_grabbed = false
	if destroy_enabled:
		resume_timedown()
	_suppress_throw_collisions()
	_handle_post_ungrab.call_deferred()


func _suppress_throw_collisions() -> void:
	_ungrab_speed = speed
	_throw_collision_suppressed = true
	_saved_collision_layer = collision_layer
	_saved_collision_mask = collision_mask
	_saved_animatable_collision_layer = _animatable_body.collision_layer
	_saved_animatable_collision_mask = _animatable_body.collision_mask
	_saved_body_collision_layer = _body_area.collision_layer
	_saved_body_collision_mask = _body_area.collision_mask
	collision_layer = 0
	collision_mask = 0
	_animatable_body.collision_layer = 0
	_animatable_body.collision_mask = 0
	_body_area.collision_layer = 0
	_body_area.collision_mask = 0


func _restore_throw_collisions() -> void:
	_throw_collision_suppressed = false
	collision_layer = _saved_collision_layer
	collision_mask = _saved_collision_mask
	_animatable_body.collision_layer = _saved_animatable_collision_layer
	_animatable_body.collision_mask = _saved_animatable_collision_mask
	_body_area.collision_layer = _saved_body_collision_layer
	_body_area.collision_mask = _saved_body_collision_mask
	_update_item_floor_collision_layer()


func _handle_post_ungrab() -> void:
	# Layer 5 stays off until stuck check passes (GrabbableModifier disables it while held).
	_break_blocked = true
	if break_if_stuck && _is_stuck_after_ungrab_via_solid_checker():
		_break_blocked = false
		break_ice(true, true)
		return
	await get_tree().physics_frame
	if !is_instance_valid(self):
		return
	_restore_throw_collisions()
	_break_blocked = false
	_restore_player_collision = true


func _try_break_if_geometry_stuck() -> void:
	if !break_if_stuck || _break_blocked || _being_grabbed || _throw_collision_suppressed:
		_geometry_stuck_pending = false
		return
	if !_restore_player_collision:
		_geometry_stuck_pending = false
		return
	if !_is_geometry_embedded():
		_geometry_stuck_pending = false
		return
	if !_geometry_stuck_pending:
		_geometry_stuck_pending = true
		return
	_geometry_stuck_pending = false
	_restore_player_collision = false
	break_ice(true, true)


func _try_break_if_player_stuck_inside() -> void:
	if !break_if_stuck || _break_blocked || _being_grabbed || _throw_collision_suppressed:
		return
	if !get_collision_layer_value(5):
		return
	if !_is_player_stuck_via_solid_checker():
		return
	_restore_player_collision = false
	break_ice(true, true)


func _try_restore_player_collision() -> void:
	if !_restore_player_collision:
		return
	if !is_on_floor() || _is_player_stuck_via_solid_checker():
		return
	_register_powerup_collision_exceptions()
	set_collision_layer_value(5, true)
	_restore_player_collision = false


func _register_powerup_collision_exceptions() -> void:
	for result in _solid_checker_intersect_shape(POWERUP_SOLID_CHECKER_MASK, 8, _powerup_solid_checker_shape, 0.0):
		var collider = result.get(&"collider")
		if !(collider is Powerup) || !is_instance_valid(collider):
			continue
		var powerup := collider as Powerup
		if powerup in _powerup_collision_exceptions:
			continue
		add_collision_exception_with(powerup)
		_powerup_collision_exceptions.append(powerup)


func _clear_powerup_collision_exceptions() -> void:
	for powerup in _powerup_collision_exceptions:
		if is_instance_valid(powerup):
			remove_collision_exception_with(powerup)
	_powerup_collision_exceptions.clear()


func _is_stuck_after_ungrab_via_solid_checker() -> bool:
	for result in _solid_checker_intersect_shape(SOLID_CHECKER_MASK, 16, _collision_shape):
		var collider = result.get(&"collider")
		if !collider || collider == self || collider.get_parent() == self:
			continue
		if collider is Player:
			continue
		if collider is CharacterBody2D && collider.has_method(&"break_ice"):
			return true
		if collider is AnimatableBody2D:
			return true
		if collider is StaticBody2D:
			return true
		if collider is TileMap or collider is TileMapLayer:
			if _has_ungrab_stuck_context():
				return true
	return false


func _is_geometry_embedded() -> bool:
	if !is_on_wall() && !is_on_ceiling():
		return false
	
	for result in _solid_checker_intersect_shape(SOLID_CHECKER_MASK, 16, _solid_checker_shape, 0.0):
		var collider = result.get(&"collider")
		if collider is CharacterBody2D && collider.has_method(&"break_ice"):
			return true
		if collider is AnimatableBody2D:
			return true
	
	for i in get_slide_collision_count():
		var _collision := get_slide_collision(i)
		if !_collision:
			continue
		var normal := _collision.get_normal()
		if !_is_wall_or_ceiling_contact(normal):
			continue
		var collider = _collision.get_collider()
		if !_is_stuck_geometry_collider(collider):
			continue
		if !(collider is TileMap or collider is TileMapLayer or collider is StaticBody2D):
			continue
		if _collision.get_depth() >= STUCK_GEOMETRY_DEPTH:
			return true
		if _solid_checker_intersect_shape(SOLID_CHECKER_MASK, 1, _solid_checker_shape, 0.0).is_empty():
			continue
		if !_can_escape_contact(normal):
			return true
	return false


func _is_stuck_geometry_collider(collider: Object) -> bool:
	if !collider || collider == self || collider.get_parent() == self:
		return false
	if collider is Player:
		return false
	if collider is CharacterBody2D && collider.has_method(&"break_ice"):
		return true
	if collider is AnimatableBody2D or collider is StaticBody2D:
		return true
	if collider is TileMap or collider is TileMapLayer:
		return true
	return false


func _is_wall_or_ceiling_contact(normal: Vector2) -> bool:
	if is_on_wall() && absf(normal.x) > 0.5:
		return true
	if is_on_ceiling() && normal.dot(up_direction) > 0.5:
		return true
	return false


func _can_escape_contact(contact_normal: Vector2) -> bool:
	if contact_normal.is_zero_approx() || !_collision_shape.shape:
		return true
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _collision_shape.shape
	query.transform = _collision_shape.global_transform
	query.collision_mask = SOLID_CHECKER_MASK
	query.margin = 0.0
	query.exclude = [get_rid(), _animatable_body.get_rid()]
	query.motion = contact_normal * STUCK_ESCAPE_DISTANCE
	var fractions: PackedFloat32Array = space_state.cast_motion(query)
	if fractions.is_empty():
		return true
	return fractions[0] >= 0.999


func _has_ungrab_stuck_context() -> bool:
	return absf(_ungrab_speed.x) > 50.0 || _ungrab_speed.y < -50.0


func _is_player_stuck_via_solid_checker() -> bool:
	if !is_instance_valid(Thunder._current_player):
		return false
	for result in _solid_checker_intersect_shape(1):
		if result.get(&"collider") is Player:
			return true
	return false


@warning_ignore("shadowed_variable_base_class")
func _solid_checker_intersect_shape(
		collision_mask: int,
		max_results: int = 8,
		shape_node: CollisionShape2D = null,
		margin: float = 1.0
) -> Array:
	var source := shape_node if shape_node else _solid_checker_shape
	if !source.shape:
		return []
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = source.shape
	query.transform = source.global_transform
	query.collision_mask = collision_mask
	query.margin = margin
	query.exclude = [get_rid(), _animatable_body.get_rid()]
	var results := space_state.intersect_shape(query, max_results)
	if !results.is_empty() || source != _collision_shape:
		return results
	var motion := _get_stuck_probe_motion()
	if motion.is_zero_approx():
		return results
	query.motion = motion
	return space_state.intersect_shape(query, max_results)


func _get_stuck_probe_motion() -> Vector2:
	for i in get_slide_collision_count():
		var _collision := get_slide_collision(i)
		if !_collision:
			continue
		var normal := _collision.get_normal()
		if is_on_wall() && absf(normal.x) > 0.5:
			return -normal * 2.0
		if is_on_ceiling() && normal.dot(up_direction) > 0.5:
			return -normal * 2.0
	return Vector2.ZERO


func _overlaps_player() -> bool:
	return _is_player_stuck_via_solid_checker()


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
	
	_prepare_powerup_solid_checker_shape()
	if !break_if_stuck:
		return
	_prepare_solid_checker_shape()


## Breaks the ice.[br]
## If [param heavy] is [code]true[/code], the object in the block will be destroyed.[br]
## [param sound_heavily] determines which type of sound will play on the ice's breaking.
func break_ice(heavy: bool = false, sound_heavily: bool = false) -> void:
	if process_mode == PROCESS_MODE_DISABLED:
		return
	
	if forced_heavy_break:
		heavy = true
		sound_heavily = true
	
	_release_contained_item(heavy)
	
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


func _release_contained_item(heavy: bool) -> void:
	if !is_instance_valid(contained_item):
		return
	
	var spawn_parent := get_parent()
	if !is_instance_valid(spawn_parent):
		return
	
	var item := contained_item
	var enemy_killed := contained_item_enemy_killed
	var sprite_offset := Vector2.ZERO
	if is_instance_valid(contained_item_sprite):
		sprite_offset = contained_item_sprite.position
	
	contained_item = null
	contained_item_enemy_killed = null
	
	spawn_parent.add_child(item)
	item.global_transform = global_transform
	item.position += sprite_offset
	
	if !heavy:
		item.position += unfreeze_offset
		item.reset_physics_interpolation()
	elif is_instance_valid(enemy_killed) && item.is_ancestor_of(enemy_killed):
		enemy_killed.got_killed(&"self")
		item.position += unfreeze_offset
		item.reset_physics_interpolation()
	else:
		item.queue_free()


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


func resume_timedown() -> void:
	_timer_destroy.paused = false


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
