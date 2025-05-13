extends NodeModifier

## Emitted when the item is grabbed.
signal grabbed
## Emitted when the item is ungrabbed.
signal ungrabbed
## Emitted when the item initiates grabbing.
signal grab_initiated
## Emitted when the player dies, and item gets ungrabbed.
signal ungrabbed_player_died

@export_group("Grabbing", "grabbing_")
## Top grabbing will lock the player's movement for a short period and play a unique animation.
@export var grabbing_top_enabled: bool = true:
	set(value):
		grabbing_top_enabled = value
		if !target_node:
			return
		if value && !target_node.is_in_group(&"#top_grabbable"):
			target_node.add_to_group(&"#top_grabbable")
		elif !value && target_node.is_in_group(&"#top_grabbable"):
			target_node.remove_from_group(&"#top_grabbable")
## Side grabbing can be used for anything if player movement lock is not needed.[br]
## If [code]false[/code], but [member grabbing_top_enabled] is [code]true[/code],
## the object can only be grabbed from the top side. Else, it can be grabbed from any side.[br][br]
## If both are [code]true[/code], [member grabbing_top_enabled] has a higher priority.
@export var grabbing_side_enabled: bool = true:
	set(value):
		grabbing_side_enabled = value
		if !target_node:
			return
		if value && !target_node.is_in_group(&"#side_grabbable"):
			target_node.add_to_group(&"#side_grabbable")
		elif !value && target_node.is_in_group(&"#side_grabbable"):
			target_node.remove_from_group(&"#side_grabbable")
@export_range(0.1, 0.5) var grabbing_top_grab_movement_lock_delay: float = 0.3
## If [code]true[/code], ungrabbing will modify target node's collisions to collide
## with the player again.
@export var grabbing_ungrab_collision_with_player: bool = true
## Use with [member grabbing_ungrab_collision_with_player]. [br][br]
## If [code]true[/code], collision will not change until the target node hits the floor.
@export var grabbing_defer_mario_collision_until_on_floor: bool = true
## Player throwing power while standing still.
@export var grabbing_ungrab_throw_power_min: Vector2 = Vector2(150, 200)
## Player throwing power while moving.
@export var grabbing_ungrab_throw_power_max: Vector2 = Vector2(400, 700)
## If [code]true[/code], the target node's [member process_mode] will be modified on
## grabbing and ungrabbing.
@export var grabbing_disable_process_when_grabbed: bool = true
@export_group("Signals", "signal_")
## Whether or not to emit the [signal ungrabbed()] signal when player dies, alongside the
## [signal ungrabbed_player_died()] signal.
@export var signal_emit_ungrabbed_when_player_dies: bool = true
@export_group("Sounds", "sound_")
@export var sound_grab_top = preload("res://engine/objects/players/prefabs/sounds/grab.wav")
@export var sound_grab_side = preload("res://engine/objects/players/prefabs/sounds/grab.wav")
@export var sound_throw = preload("res://engine/objects/players/prefabs/sounds/kick.wav")

@onready var player: Player = Thunder._current_player

var _player_lock_pos: Vector2
var _from_follow_pos: Vector2
var _follow_progress: float
var _grabbed: bool
var _following_start: bool
var _following: bool
var _wait_until_floor: bool


func _ready() -> void:
	if grabbing_top_enabled:
		target_node.add_to_group(&"#top_grabbable")
	if grabbing_side_enabled:
		target_node.add_to_group(&"#side_grabbable")

	if !target_node.has_signal(&"grabbing_got_top_grabbed"):
		target_node.add_user_signal(&"grabbing_got_top_grabbed")
	if !target_node.has_signal(&"grabbing_got_side_grabbed"):
		target_node.add_user_signal(&"grabbing_got_side_grabbed")
	if !target_node.has_signal(&"grabbing_got_thrown"):
		target_node.add_user_signal(&"grabbing_got_thrown")

	target_node.connect(&"grabbing_got_top_grabbed", _top_grabbed)
	target_node.connect(&"grabbing_got_side_grabbed", _side_grabbed)
	target_node.connect(&"grabbing_got_thrown", _do_ungrab)


func _physics_process(delta: float) -> void:
	if _grabbed && _following_start:
		var _target = get_target_hold_position()
		target_node.global_position = lerp(_from_follow_pos, _target, _follow_progress)
		_follow_progress = min(_follow_progress + 5 * delta, 1)
		if _follow_progress == 1:
			_follow_progress = 0
			_following_start = false
			_following = true

	if _grabbed && _following:
		target_node.global_position = get_target_hold_position()

	if !_grabbed && _wait_until_floor && target_node.is_on_floor():
		var pl = Thunder._current_player
		if pl && grabbing_ungrab_collision_with_player:
			if _check_for_player_collision(pl):
				target_node.set_collision_layer_value(5, true)
				_wait_until_floor = false
		else:
			_wait_until_floor = false


func _check_for_player_collision(pl: Player) -> bool:
	var space_state: PhysicsDirectSpaceState2D = target_node.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.collision_mask = 1
	
	for i in target_node.get_shape_owners():
		query.transform = (target_node.shape_owner_get_owner(i) as Node2D).global_transform
		for j in target_node.shape_owner_get_shape_count(i):
			query.shape = target_node.shape_owner_get_shape(i, j)
			
			var results = space_state.intersect_shape(query, 16)
			for k in results:
				var l: Object = k.get(&"collider", null)
				if l && l is Player:
					return false
	return true


func _top_grabbed() -> void:
	Audio.play_sound(sound_grab_top, player)
	player.is_holding = true
	grab_initiated.emit()
	await _do_player_lock()
	_do_grab()


func _side_grabbed() -> void:
	Audio.play_sound(sound_grab_side, player)
	grab_initiated.emit()
	_do_grab()


func _do_player_lock() -> void:
	_player_lock_pos = player.global_position
	player.no_movement = true
	await player.get_tree().create_timer(grabbing_top_grab_movement_lock_delay, false, true).timeout
	player.no_movement = false


func _do_grab() -> void:
	if target_node is GravityBody2D:
		_grabbed = true
		if grabbing_disable_process_when_grabbed:
			target_node.process_mode = Node.PROCESS_MODE_DISABLED
		player.is_holding = true
		player.holding_item = target_node
		_from_follow_pos = target_node.global_position
		_following_start = true

	grabbed.emit()


func _do_ungrab(player_died: bool) -> void:
	if player_died:
		if target_node is GravityBody2D:
			_grabbed = false
			if grabbing_disable_process_when_grabbed:
				target_node.process_mode = Node.PROCESS_MODE_INHERIT
			_follow_progress = false
			_following_start = false
			_following = false
		
		if grabbing_defer_mario_collision_until_on_floor && target_node.get_collision_layer_value(5):
			target_node.set_collision_layer_value(5, false)
			_wait_until_floor = true
		
		ungrabbed.emit()
		ungrabbed_player_died.emit()
		return
	
	Audio.play_sound(sound_throw, player)
	if target_node is GravityBody2D:
		_grabbed = false
		if grabbing_disable_process_when_grabbed:
			target_node.process_mode = Node.PROCESS_MODE_INHERIT
		player.holding_item = null
		_follow_progress = false
		_following_start = false
		_following = false

		if player.left_right != 0:
			target_node.speed.x = grabbing_ungrab_throw_power_max.x * player.direction
		if player.left_right == 0:
			target_node.speed.x = grabbing_ungrab_throw_power_min.x * player.direction
		if player.up_down < 0:
			target_node.speed.y = grabbing_ungrab_throw_power_max.y * -1
			if player.left_right == 0:
				target_node.speed.x = 0
		if player.up_down == 0:
			target_node.speed.y = grabbing_ungrab_throw_power_min.y * -1

		if grabbing_defer_mario_collision_until_on_floor && target_node.get_collision_layer_value(5):
			target_node.set_collision_layer_value(5, false)
			_wait_until_floor = true

		#await player.get_tree().physics_frame
		player.set_deferred("is_holding", false)

	ungrabbed.emit()

func get_target_hold_position() -> Vector2:
	return player.global_position + player.suit.physics_shaper.shape_pos + Vector2(16 * player.direction, 0)
