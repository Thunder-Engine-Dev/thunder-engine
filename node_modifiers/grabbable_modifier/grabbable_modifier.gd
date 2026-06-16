extends NodeModifier

## Emitted when the item is grabbed by player.
signal grabbed
## Emitted when the item is ungrabbed by player.
signal ungrabbed
## Emitted when the item initiates grabbing by player.
signal grab_initiated
## Emitted when the player dies, and item gets ungrabbed.
signal ungrabbed_player_died

## Emitted when the item is grabbed by enemy.
signal enemy_grabbed
## Emitted when the item is ungrabbed by enemy.
signal enemy_ungrabbed
## Emitted when the item initiates grabbing by enemy.
signal enemy_grab_initiated
## Emitted when the enemy that was holding the item dies.
signal enemy_owner_died

const DEFAULT_GRAB_SOUND = preload("res://engine/objects/players/prefabs/sounds/grab.wav")
const DEFAULT_KICK_SOUND = preload("res://engine/objects/players/prefabs/sounds/kick.wav")

enum PlayerLockMethod {
	## No changes happen to the player's physics when top-grabbing, and no animations play.
	DISABLED,
	## Player's speed gets drastically decreased the moment top-grabbing is initiated.
	LOSE_SPEED,
	## Player's movement gets completely locked for a specified period of time when top-grabbing.[br]
	## This is the only method that causes a unique animation to play.
	LOCK_MOVEMENT,
}

@export_group("Grabbing", "grabbing_")
## Top grabbing will lock the player's movement for a short period and play a unique animation.[br][br]
## Specify the lock method in [member grabbing_top_lock_method].
@export var grabbing_top_enabled: bool = true:
	set(value):
		grabbing_top_enabled = value
		if !target_node:
			return
		if value && !target_node.is_in_group(&"#top_grabbable"):
			target_node.add_to_group(&"#top_grabbable")
		elif !value && target_node.is_in_group(&"#top_grabbable"):
			target_node.remove_from_group(&"#top_grabbable")
## Side grabbing can be used to be able to grab the item from the left and right sides.[br]
## If [code]true[/code], but [member grabbing_top_enabled] is [code]false[/code],
## the object can only be grabbed from the left or right sides.
## If both are [code]true[/code], the object can be grabbed from any side, except for the bottom.
@export var grabbing_side_enabled: bool = true:
	set(value):
		grabbing_side_enabled = value
		if !target_node:
			return
		if value && !target_node.is_in_group(&"#side_grabbable"):
			target_node.add_to_group(&"#side_grabbable")
		elif !value && target_node.is_in_group(&"#side_grabbable"):
			target_node.remove_from_group(&"#side_grabbable")
## Special enemies that can grab items, such as the Buster Beetle, will be able to grab the item,
## setting the item's [member belongs_to] property to [enum Data.PROJECTILE_BELONGS.ENEMY].[br][br]
## See the respective signals prefixed with [code]enemy_[/code].
@export var grabbing_enemy_can_grab: bool = true
@export_subgroup("Top Grabbing", "grabbing_top_")
## Specifies how the player's physics should react when top-grabbing the object.
@export var grabbing_top_lock_method := PlayerLockMethod.LOSE_SPEED
## Effective only for [enum PlayerLockMethod.LOCK_MOVEMENT]. Specified in seconds.
@export_range(0.1, 0.5) var grabbing_top_grab_movement_lock_delay: float = 0.3
## Effective only for [enum PlayerLockMethod.LOSE_SPEED]. Multiplies player's X speed by this value.
@export_range(0.0, 1.0) var grabbing_top_grab_lose_speed_multiplier: float = 0.33
## If [code]true[/code], the target node's [member process_mode] will be modified on
## grabbing and ungrabbing.
@export var grabbing_disable_process_when_grabbed: bool = true
## Z-Index of the target node will match that of player's, e.g. when warping.
@export var grabbing_match_player_z_index: bool = true
@export_subgroup("Ungrabbing", "grabbing_")
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
# ## Player throwing power while holding UP and moving (diagonal).
#@export var grabbing_ungrab_throw_power_diagonal: Vector2 = Vector2(400, 500)
## If [code]true[/code], after the follow-in completes, the item is thrown when the player
## [i]is not[/i] holding the attack input ([code]!player.attacking[/code]).
@export var grabbing_ungrab_on_attack_release: bool = false
## If [code]true[/code], [method _do_ungrab] does not play [member sound_throw] (e.g. when the
## target will play it later or when death SFX may follow immediately, avoiding double kick).
@export var grabbing_suppress_ungrab_throw_sound: bool = false
## If [code]false[/code], [method _do_ungrab] will not set the target [member GeneralMovementBody2D.speed]
## from the player (use e.g. item-specific logic in [signal ungrabbed]).
@export var grabbing_apply_player_throw_velocity: bool = true
@export_subgroup("Enemy (Un)Grabbing", "enemy_")
@export var enemy_ungrab_throw_power: Vector2 = Vector2(300, 250)
@export_group("Signals", "signal_")
## If [code]true[/code], the [signal ungrabbed] signal is also emitted (after setting
## [const META_UNGRAB_FROM_PLAYER_DEATH] on the target) when the ungrab was caused by
## player death. If [code]false[/code], only [signal ungrabbed_player_died] is emitted.
@export var signal_emit_ungrabbed_when_player_dies: bool = true
@export_group("Sounds", "sound_")
@export var sound_grab_top = DEFAULT_GRAB_SOUND
@export var sound_grab_side = DEFAULT_GRAB_SOUND
@export var sound_throw = DEFAULT_KICK_SOUND

@onready var player: Player = Thunder._current_player
@onready var old_z_index: int = target_node.z_index

var belongs_to := Data.PROJECTILE_BELONGS.PLAYER
var owner_enemy: Node2D

var _player_lock_pos: Vector2
var _from_follow_pos: Vector2
var _follow_progress: float
var _grabbed: bool
var _following_start: bool
var _following: bool
var _wait_until_floor: bool
var _match_z_index: bool
## Bit 5 on the target at grab time. If [code]false[/code], defer logic must not add or re-enable that bit.
var _player_collision_layer5_before_grab: bool = false

## See [method Player.control_process] — items that use [member grabbing_ungrab_on_attack_release]
## must not use the default "press attack to throw" path on the player.
const META_GRAB_SKIP_ATTACK_INPUT_THROW: StringName = &"grabbing_skip_attack_input_throw"
## Set only for the [signal ungrabbed] callback when [method _do_ungrab] was called with
## [param player_died] [code]true[/code] (so listeners can tell death ungrab from a normal throw).
const META_UNGRAB_FROM_PLAYER_DEATH: StringName = &"grabbable_ungrab_from_player_death"


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
	
	target_node.connect(&"grabbing_got_top_grabbed", _top_grabbed.bind(true))
	target_node.connect(&"grabbing_got_side_grabbed", _side_grabbed.bind(true))
	target_node.connect(&"grabbing_got_thrown", _do_ungrab)
	
	if !target_node.has_signal(&"grabbing_enemy_got_top_grabbed"):
		target_node.add_user_signal(&"grabbing_enemy_got_top_grabbed")
	if !target_node.has_signal(&"grabbing_enemy_got_side_grabbed"):
		target_node.add_user_signal(&"grabbing_enemy_got_side_grabbed")
	if !target_node.has_signal(&"grabbing_enemy_got_thrown"):
		target_node.add_user_signal(&"grabbing_enemy_got_thrown")
	
	target_node.connect(&"grabbing_enemy_got_top_grabbed", _top_grabbed.bind(false))
	target_node.connect(&"grabbing_enemy_got_side_grabbed", _side_grabbed.bind(false))
	target_node.connect(&"grabbing_enemy_got_thrown", _do_enemy_ungrab)
	
	if !target_node.has_meta(&"grabbable_modifier"):
		target_node.set_meta(&"grabbable_modifier", self)


func _physics_process(delta: float) -> void:
	if _grabbed && _following_start:
		var _target: Vector2 = _resolve_hold_position()
		target_node.global_position = lerp(_from_follow_pos, _target, _follow_progress)
		if belongs_to == Data.PROJECTILE_BELONGS.PLAYER:
			_follow_progress = min(_follow_progress + 5 * delta, 1)
		else:
			_follow_progress = min(_follow_progress + 3 * delta, 1)
		if _follow_progress == 1:
			_follow_progress = 0
			_following_start = false
			_following = true
	
	if belongs_to == Data.PROJECTILE_BELONGS.ENEMY:
		if !is_instance_valid(owner_enemy):
			_do_enemy_ungrab(true)
			return
		if _grabbed && _following:
			target_node.global_position = _resolve_hold_position()
		return
	
	if _grabbed && _following && is_instance_valid(player):
		target_node.global_position = _resolve_hold_position()
		if _match_z_index:
			var _warp_tweak: bool = CharacterManager.get_suit_tweak("warp_animation", "", player.suit.name)
			target_node.z_index = player.sprite_container.z_index + int(_warp_tweak)

	if _grabbed && _following && !_following_start && grabbing_ungrab_on_attack_release && is_instance_valid(player) && !player.attacking:
		if target_node.has_signal(&"grabbing_got_thrown"):
			target_node.emit_signal(&"grabbing_got_thrown", false)

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


func _resolve_hold_position() -> Vector2:
	if (!is_instance_valid(player) && belongs_to == Data.PROJECTILE_BELONGS.PLAYER) || !is_instance_valid(target_node):
		return target_node.global_position if is_instance_valid(target_node) else Vector2()
	if belongs_to == Data.PROJECTILE_BELONGS.ENEMY:
		if target_node.has_method(&"grabbable_get_enemy_hold_global_position"):
			return target_node.call(&"grabbable_get_enemy_hold_global_position") as Vector2
		return target_node.global_position
	
	var _warp_tweak: bool = CharacterManager.get_suit_tweak("warp_animation", "", player.suit.name)
	if target_node.has_method(&"grabbable_get_hold_global_position"):
		return target_node.call(&"grabbable_get_hold_global_position", _warp_tweak) as Vector2
	return get_target_hold_position(_warp_tweak)


func _top_grabbed(by_player: bool = true) -> void:
	if is_queued_for_deletion(): return
	if !by_player:
		belongs_to = Data.PROJECTILE_BELONGS.ENEMY
		enemy_grab_initiated.emit()
		_do_enemy_grab()
		return
	
	var _sfx = CharacterManager.get_sound_replace(sound_grab_top, DEFAULT_GRAB_SOUND, "grab", true)
	Audio.play_sound(_sfx, player, false)
	player.is_holding = true
	belongs_to = Data.PROJECTILE_BELONGS.PLAYER
	grab_initiated.emit()
	
	await _do_player_lock()
	_do_grab()


func _side_grabbed(by_player: bool = true) -> void:
	if is_queued_for_deletion(): return
	if !by_player:
		belongs_to = Data.PROJECTILE_BELONGS.ENEMY
		enemy_grab_initiated.emit()
		_do_enemy_grab()
		return
	
	var _sfx = CharacterManager.get_sound_replace(sound_grab_side, DEFAULT_GRAB_SOUND, "grab", true)
	Audio.play_sound(_sfx, player, false)
	belongs_to = Data.PROJECTILE_BELONGS.PLAYER
	grab_initiated.emit()
	_do_grab()


func _do_player_lock() -> void:
	match grabbing_top_lock_method:
		PlayerLockMethod.LOSE_SPEED:
			player.speed.x *= grabbing_top_grab_lose_speed_multiplier
		PlayerLockMethod.LOCK_MOVEMENT:
			_player_lock_pos = player.global_position
			player.no_movement = true
			await player.get_tree().create_timer(grabbing_top_grab_movement_lock_delay, false, true).timeout
			if !is_instance_valid(player):
				return
			player.no_movement = false


func _do_grab() -> void:
	if grabbing_match_player_z_index:
		_match_z_index = true
	
	if target_node is GravityBody2D:
		_grabbed = true
		if grabbing_disable_process_when_grabbed:
			target_node.process_mode = Node.PROCESS_MODE_DISABLED
		player.is_holding = true
		player.holding_item = target_node
		_from_follow_pos = target_node.global_position
		_following_start = true
		if grabbing_defer_mario_collision_until_on_floor:
			_player_collision_layer5_before_grab = target_node.get_collision_layer_value(5)
			if _player_collision_layer5_before_grab:
				target_node.set_collision_layer_value(5, false)
	if grabbing_ungrab_on_attack_release:
		target_node.set_meta(META_GRAB_SKIP_ATTACK_INPUT_THROW, true)

	grabbed.emit()


func _do_ungrab(player_died: bool) -> void:
	if target_node.has_meta(META_GRAB_SKIP_ATTACK_INPUT_THROW):
		target_node.remove_meta(META_GRAB_SKIP_ATTACK_INPUT_THROW)
	if grabbing_match_player_z_index:
		_match_z_index = false
		target_node.z_index = old_z_index
	
	if player_died:
		if target_node is GravityBody2D:
			_grabbed = false
			if grabbing_disable_process_when_grabbed:
				target_node.process_mode = Node.PROCESS_MODE_INHERIT
			_follow_progress = false
			_following_start = false
			_following = false
		
		if grabbing_defer_mario_collision_until_on_floor && _player_collision_layer5_before_grab:
			target_node.set_collision_layer_value(5, false)
			_wait_until_floor = true

		if signal_emit_ungrabbed_when_player_dies:
			target_node.set_meta(META_UNGRAB_FROM_PLAYER_DEATH, true)
			ungrabbed.emit()
			if target_node.has_meta(META_UNGRAB_FROM_PLAYER_DEATH):
				target_node.remove_meta(META_UNGRAB_FROM_PLAYER_DEATH)
		ungrabbed_player_died.emit()
		return
	
	if !grabbing_suppress_ungrab_throw_sound:
		var _sfx = CharacterManager.get_sound_replace(sound_throw, DEFAULT_KICK_SOUND, "kick", true)
		Audio.play_sound(_sfx, player, false)
	if target_node is GravityBody2D:
		_grabbed = false
		if grabbing_disable_process_when_grabbed:
			target_node.process_mode = Node.PROCESS_MODE_INHERIT
		player.holding_item = null
		_follow_progress = false
		_following_start = false
		_following = false

		if grabbing_apply_player_throw_velocity:
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

		if grabbing_defer_mario_collision_until_on_floor && _player_collision_layer5_before_grab:
			target_node.set_collision_layer_value(5, false)
			_wait_until_floor = true

		#await player.get_tree().physics_frame
		player.set_deferred("is_holding", false)
		if grabbing_ungrab_on_attack_release && is_instance_valid(player):
			player.threw.emit()

	ungrabbed.emit()


func _do_enemy_grab() -> void:
	if target_node is GravityBody2D:
		_grabbed = true
		if grabbing_disable_process_when_grabbed:
			target_node.process_mode = Node.PROCESS_MODE_DISABLED
		_from_follow_pos = target_node.global_position
		_following_start = true

	enemy_grabbed.emit()


func _do_enemy_ungrab(enemy_died: bool = false) -> void:
	if target_node is GravityBody2D:
		_grabbed = false
		owner_enemy = null
		if grabbing_disable_process_when_grabbed:
			target_node.process_mode = Node.PROCESS_MODE_INHERIT
		_follow_progress = false
		_following_start = false
		_following = false
	
	if enemy_died:
		enemy_owner_died.emit()
		return
	enemy_ungrabbed.emit()


func get_target_hold_position(_warp_tweak: bool = false) -> Vector2:
	if !_warp_tweak && player.warp != player.Warp.NONE && player.warp_dir >= player.WarpDir.UP:
		return player.global_position + player.suit.physics_shaper.shape_pos
	return player.global_position + player.suit.physics_shaper.shape_pos + Vector2(
		16 * player.direction,
		12 * int(player.is_crouching)
	)
