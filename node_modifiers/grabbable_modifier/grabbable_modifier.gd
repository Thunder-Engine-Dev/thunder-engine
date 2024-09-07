extends NodeModifier

@export_group("Grabbing", "grabbing_")
@export var grabbing_top_enabled: bool = true
@export var grabbing_side_enabled: bool = true
@export var grabbing_defer_mario_collision_until_on_floor: bool = true
@export var grabbing_ungrab_throw_power_min: Vector2 = Vector2(150, 200)
@export var grabbing_ungrab_throw_power_max: Vector2 = Vector2(400, 700)
@export_group("Sounds", "sound_")
@export var sound_grab_top = preload("res://engine/objects/players/prefabs/sounds/grab.wav")
@export var sound_grab_side = preload("res://engine/objects/players/prefabs/sounds/grab.wav")
@export var sound_throw = preload("res://engine/objects/players/prefabs/sounds/kick.wav")

@onready var player = Thunder._current_player

var _player_lock: bool
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
	
	target_node.add_user_signal(&"grabbing_got_top_grabbed")
	target_node.add_user_signal(&"grabbing_got_side_grabbed")
	target_node.add_user_signal(&"grabbing_got_thrown")
	
	target_node.connect(&"grabbing_got_top_grabbed", _top_grabbed)
	target_node.connect(&"grabbing_got_side_grabbed", _side_grabbed)
	target_node.connect(&"grabbing_got_thrown", _do_ungrab)


func _top_grabbed() -> void:
	Audio.play_sound(sound_grab_top, player)
	player.is_holding = true
	await _do_player_lock()
	_do_grab()
	pass


func _side_grabbed() -> void:
	Audio.play_sound(sound_grab_side, player)
	_do_grab()
	pass


func _do_player_lock() -> void:
	_player_lock_pos = player.global_position
	_player_lock = true
	await player.get_tree().create_timer(0.3, false, true).timeout
	_player_lock = false


func _do_grab() -> void:
	if target_node is GravityBody2D:
		_grabbed = true
		target_node.process_mode = Node.PROCESS_MODE_DISABLED
		player.is_holding = true
		player.holding_item = target_node
		_from_follow_pos = target_node.global_position
		_following_start = true


func _do_ungrab(player_died: bool) -> void:
	Audio.play_sound(sound_throw, player)
	if target_node is GravityBody2D:
		_grabbed = false
		target_node.process_mode = Node.PROCESS_MODE_INHERIT
		player.holding_item = null
		_follow_progress = false
		_following_start = false
		_following = false
		
		if player.left_right != 0:
			target_node.speed.x = grabbing_ungrab_throw_power_max.x * player.direction
		if player.left_right == 0:
			target_node.speed.x = grabbing_ungrab_throw_power_min.x * player.direction
		if player.up_down == -1:
			target_node.speed.y = grabbing_ungrab_throw_power_max.y * -1
			if player.left_right == 0:
				target_node.speed.x = 0
		if player.up_down == 0:
			target_node.speed.y = grabbing_ungrab_throw_power_min.y * -1
		
		if grabbing_defer_mario_collision_until_on_floor && target_node.get_collision_layer_value(5):
			target_node.set_collision_layer_value(5, false)
			_wait_until_floor = true
		
		await player.get_tree().physics_frame
		player.is_holding = false


func _physics_process(delta: float) -> void:
	if _player_lock:
		player.speed = Vector2.ZERO
		player.global_position = _player_lock_pos
	
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
		target_node.set_collision_layer_value(5, true)
		_wait_until_floor = false


func get_target_hold_position() -> Vector2:
	return player.global_position + player.suit.physics_shaper.shape_pos + Vector2(16 * player.direction, 0)
