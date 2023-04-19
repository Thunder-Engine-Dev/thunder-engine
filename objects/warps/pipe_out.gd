@tool
extends Area2D

@export_category("PipeOut")
@export var warp_direction: PlayerStatesManager.WarpDirection = PlayerStatesManager.WarpDirection.UP
@export var warping_speed: float = 50
@export var warping_sound: AudioStream = preload("res://engine/objects/mario/sounds/pipe.wav")
@export var trigger_immediately: bool = false

var player: Player

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var pos_player: Marker2D = $PosPlayer


func _ready() -> void:
	if Engine.is_editor_hint(): return
	$Arrow.queue_free()
	$TextDir.queue_free()
	
	if trigger_immediately:
		player = Thunder._current_player
		player.states.set_state("warp")
		player.states.warp_direction = warp_direction
		player.global_position = pos_player.global_position
		player.z_index = -5
		pass_player(player)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		_label()
		return
	if !player: return
	
	player.global_position += Vector2.UP.rotated(global_rotation) * warping_speed * delta


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player.states.set_state("default")
		player.z_index = 1
		player = null
		Thunder._current_hud.timer.paused = false


func pass_player(new_player: Player) -> void:
	if Engine.is_editor_hint(): return
	if !is_instance_valid(new_player): return
	
	player = new_player
	
	var player_warp_dir: PlayerStatesManager.WarpDirection
	
	match warp_direction:
		PlayerStatesManager.WarpDirection.RIGHT:
			pos_player.position = Vector2((shape.shape as RectangleShape2D).size.x,0)
			player_warp_dir = PlayerStatesManager.WarpDirection.RIGHT
		PlayerStatesManager.WarpDirection.LEFT:
			pos_player.position = Vector2(-(shape.shape as RectangleShape2D).size.x,0)
			player_warp_dir = PlayerStatesManager.WarpDirection.LEFT
		PlayerStatesManager.WarpDirection.DOWN:
			pos_player.position = Vector2(0,(shape.shape as RectangleShape2D).size.y - (player.collision.shape as RectangleShape2D).size.y)
			player_warp_dir = PlayerStatesManager.WarpDirection.UP
		PlayerStatesManager.WarpDirection.UP:
			pos_player.position = Vector2(0,(shape.shape as RectangleShape2D).size.y)
			player_warp_dir = PlayerStatesManager.WarpDirection.DOWN
	
	player.global_position = pos_player.global_position
	player.states.warp_direction = player_warp_dir
	
	await get_tree().process_frame
	Audio.play_sound(warping_sound, self, false)


func _label() -> void:
	var text: Label = $TextDir
	text.rotation = -global_rotation
	text.scale = Vector2.ONE / 1.5
	match warp_direction:
		PlayerStatesManager.WarpDirection.RIGHT: text.text = "right"
		PlayerStatesManager.WarpDirection.LEFT: text.text = "left"
		PlayerStatesManager.WarpDirection.UP: text.text = "up"
		PlayerStatesManager.WarpDirection.DOWN: text.text = "down"
		_: ""
