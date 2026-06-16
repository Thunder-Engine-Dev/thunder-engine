@icon("res://engine/objects/warps/icons/pipe_out.svg")
@tool
extends Area2D

const DEFAULT_WARP_SOUND = preload("res://engine/objects/players/prefabs/sounds/pipe.wav")

signal warp_ended

@export_category("PipeOut")
@export var warp_direction: Player.WarpDir = Player.WarpDir.UP
@export var warping_speed: float = 50
@export var warping_sound: AudioStream = DEFAULT_WARP_SOUND
@export var trigger_immediately: bool = false

var player: Player
var player_z_index: int
var warp_invisible_left_right: bool = true

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var pos_player: Marker2D = $PosPlayer
@onready var pos_player_invisible = $PosPlayerInvisible

func _ready() -> void:
	if Engine.is_editor_hint(): return
	$Arrow.queue_free()
	$TextDir.queue_free()
	body_exited.connect(_on_body_exited)
	
	if trigger_immediately && Data.values.checkpoint == -1:
		player = Thunder._current_player
		player_z_index = player.sprite_container.z_index
		player.speed = Vector2.ZERO
		player.warp = Player.Warp.OUT
		pass_player.call_deferred(player)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		_label()
		return
	
	if !is_instance_valid(player): return
	
	player.global_position += _get_warp_exit_axis() * warping_speed * delta
	player.sync_position()
	_tweak_process()


func _get_warp_exit_axis() -> Vector2:
	return Vector2.UP.rotated(global_rotation)


func _get_collision_shape_corners(collision_shape: CollisionShape2D) -> PackedVector2Array:
	var rect_shape := collision_shape.shape as RectangleShape2D
	if !rect_shape:
		return PackedVector2Array()
	
	var half := rect_shape.size * 0.5
	var local_corners := PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	var corners := PackedVector2Array()
	corners.resize(local_corners.size())
	for i in local_corners.size():
		corners[i] = collision_shape.global_transform * local_corners[i]
	return corners


func _project_bounds_on_axis(corners: PackedVector2Array, axis: Vector2) -> Vector2:
	var min_p := INF
	var max_p := -INF
	for corner in corners:
		var projection := corner.dot(axis)
		min_p = minf(min_p, projection)
		max_p = maxf(max_p, projection)
	return Vector2(min_p, max_p)


func _snap_player_to_warp_edge(exiting_player: Player) -> void:
	var exit_axis := _get_warp_exit_axis()
	var area_corners := _get_collision_shape_corners(shape)
	var player_corners := _get_collision_shape_corners(exiting_player.collision_shape)
	if area_corners.is_empty() || player_corners.is_empty():
		return
	
	var area_bounds := _project_bounds_on_axis(area_corners, exit_axis)
	var player_bounds := _project_bounds_on_axis(player_corners, exit_axis)
	var gap := player_bounds.x - area_bounds.y
	if is_zero_approx(gap):
		return
	
	exiting_player.global_position -= exit_axis * gap
	exiting_player.reset_physics_interpolation()


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		_snap_player_to_warp_edge(player)
		player.sync_position()
		player.warp = Player.Warp.NONE
		player.sprite_container.z_index = player_z_index
		player = null
		Thunder._current_hud.timer.paused = false
		
		player_z_index = 0
		warp_ended.emit()


func _tweak_process() -> void:
	if !warp_invisible_left_right: return
	if !is_instance_valid(player.get("sprite")): return
	
	if warp_direction == Player.WarpDir.RIGHT:
		player.sprite.visible = player.global_position.x > pos_player_invisible.global_position.x
	elif warp_direction == Player.WarpDir.LEFT:
		player.sprite.visible = player.global_position.x < pos_player_invisible.global_position.x
	elif warp_direction == Player.WarpDir.UP || warp_direction == Player.WarpDir.DOWN:
		player.sprite.visible = true


func pass_player(new_player: Player) -> void:
	if Engine.is_editor_hint(): return
	if !is_instance_valid(new_player): return
	player = new_player
	
	# Recover z_index if called directly
	player_z_index = player.sprite_container.z_index
	
	var player_warp_dir: Player.WarpDir
	
	match warp_direction:
		Player.WarpDir.RIGHT:
			pos_player.position = Vector2(0, (shape.shape as RectangleShape2D).size.x)
			player_warp_dir = Player.WarpDir.RIGHT
		Player.WarpDir.LEFT:
			pos_player.position = Vector2(0, (shape.shape as RectangleShape2D).size.x)
			player_warp_dir = Player.WarpDir.LEFT
		Player.WarpDir.DOWN:
			pos_player.position = Vector2(0, (shape.shape as RectangleShape2D).size.y) #- (player.collision_shape.shape as RectangleShape2D).size.y + 20)
			player_warp_dir = Player.WarpDir.UP
		Player.WarpDir.UP:
			pos_player.position = Vector2(0, (shape.shape as RectangleShape2D).size.y + 8)
			player_warp_dir = Player.WarpDir.DOWN
	
	player.global_position = pos_player.global_position
	player.reset_physics_interpolation()
	var cam: PlayerCamera2D = Thunder._current_camera
	if cam:
		cam.teleport(true, true)
		
	
	player.warp_dir = player_warp_dir
	player.sprite_container.z_index = -5
	player.warp = Player.Warp.OUT
	
	await get_tree().physics_frame
	var _custom_sound = CharacterManager.get_sound_replace(warping_sound, DEFAULT_WARP_SOUND, "pipe_out", true)
	Audio.play_sound(_custom_sound, self, false)
	#await get_tree().physics_frame


func _label() -> void:
	var text: Label = $TextDir
	text.rotation = -global_rotation
	text.scale = Vector2.ONE / 1.5
	match warp_direction:
		Player.WarpDir.RIGHT: text.text = "right"
		Player.WarpDir.LEFT: text.text = "left"
		Player.WarpDir.UP: text.text = "up"
		Player.WarpDir.DOWN: text.text = "down"
		_: ""
