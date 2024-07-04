@icon("res://engine/objects/warps/icons/pipe_out.svg")
@tool
extends Area2D

signal warp_ended

@export_category("PipeOut")
@export var warp_direction: Player.WarpDir = Player.WarpDir.UP
@export var warping_speed: float = 50
@export var warping_sound: AudioStream = preload("res://engine/objects/players/prefabs/sounds/pipe.wav")
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
		player_z_index = player.z_index
		player.speed = Vector2.ZERO
		pass_player(player)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		_label()
		return
	if !is_instance_valid(player): return
	
	player.global_position += Vector2.UP.rotated(global_rotation) * warping_speed * delta
	_tweak_process()


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player.warp = Player.Warp.NONE
		player.z_index = player_z_index
		player = null
		Thunder._current_hud.timer.paused = false
		
		player_z_index = 0
		warp_ended.emit()


func _tweak_process() -> void:
	if !warp_invisible_left_right: return
	
	if warp_direction == Player.WarpDir.RIGHT && player.global_position.x > pos_player_invisible.global_position.x:
		player.sprite.visible = true
	elif warp_direction == Player.WarpDir.LEFT && player.global_position.x < pos_player_invisible.global_position.x:
		player.sprite.visible = true
	elif warp_direction == Player.WarpDir.UP || warp_direction == Player.WarpDir.DOWN:
		player.sprite.visible = true


func pass_player(new_player: Player) -> void:
	if Engine.is_editor_hint(): return
	if !is_instance_valid(new_player): return
	player = new_player
	
	# Recover z_index if called directly
	player_z_index = player.z_index
	
	var player_warp_dir: Player.WarpDir
	
	match warp_direction:
		Player.WarpDir.RIGHT:
			pos_player.position = Vector2(0, (shape.shape as RectangleShape2D).size.x)
			player_warp_dir = Player.WarpDir.RIGHT
		Player.WarpDir.LEFT:
			pos_player.position = Vector2(0, -(shape.shape as RectangleShape2D).size.x)
			player_warp_dir = Player.WarpDir.LEFT
		Player.WarpDir.DOWN:
			pos_player.position = Vector2(0, (shape.shape as RectangleShape2D).size.y - (player.collision_shape.shape as RectangleShape2D).size.y + 20)
			player_warp_dir = Player.WarpDir.UP
		Player.WarpDir.UP:
			pos_player.position = Vector2(0, (shape.shape as RectangleShape2D).size.y + 8)
			player_warp_dir = Player.WarpDir.DOWN
	
	player.global_position = pos_player.global_position
	player.warp_dir = player_warp_dir
	player.z_index = -5
	player.warp = Player.Warp.OUT
	
	await get_tree().process_frame
	await get_tree().process_frame
	Audio.play_sound(warping_sound, self, false)


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
