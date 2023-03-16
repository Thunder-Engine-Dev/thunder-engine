@tool
extends Area2D

@export_category("Warp")
@export_group("General")
@export var warp_direction: PlayerStatesManager.WarpDirection = PlayerStatesManager.WarpDirection.DOWN
@export_node_path("Area2D") var warp_to: NodePath
@export var warping_speed: float = 50
@export var warping_sound: AudioStream = preload("res://engine/objects/mario/sounds/pipe.wav")
@export_group("Transition")
@export var warp_path: Path2D
@export var warp_path_speed: float = 400
@export_group("Editor","warp_editor_")
@export var warping_editor_display: bool = true
@export var warping_editor_color: Color = Color(0.5,1,0.3,0.6)

var player: Player
var warp_trans: WarpTrans

var _on_warp: bool
var _duration: float
var _target: float = 1

@onready var target: Area2D = get_node_or_null(warp_to)
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var pos_player: Marker2D = $PosPlayer


func _ready() -> void:
	if Engine.is_editor_hint(): return
	$Arrow.queue_free()
	$TextDir.queue_free()

func _draw() -> void:
	if !Engine.is_editor_hint(): return
	
	draw_set_transform(Vector2.ZERO, -global_rotation, Vector2(1/global_scale.x, 1/global_scale.y))
	
	var tg:Area2D = get_node_or_null(warp_to)
	if !tg: return
	if !tg.is_in_group("pipe_out"): return
	
	draw_line(Vector2.ZERO,tg.global_position - global_position, warping_editor_color,4)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		_label()
		return
	if !player: return
	
	var input_x: int = int(Input.get_axis(player.config.control_left,player.config.control_right))
	var input_y: int = int(Input.get_axis(player.config.control_up,player.config.control_down))
	
	
	if !_on_warp && player.states.current_state != "warp":
		if input_x > 0 && warp_direction == PlayerStatesManager.WarpDirection.RIGHT:
			_on_warp = true
			pos_player.position = Vector2(-(shape.shape as RectangleShape2D).size.x / 2,0)
		elif input_x < 0 && warp_direction == PlayerStatesManager.WarpDirection.LEFT:
			_on_warp = true
			pos_player.position = Vector2((shape.shape as RectangleShape2D).size.x / 2,0)
		if input_y > 0 && warp_direction == PlayerStatesManager.WarpDirection.DOWN:
			_on_warp = true
			pos_player.position = Vector2(0,(shape.shape as RectangleShape2D).size.y)
		elif input_y < 0 && warp_direction == PlayerStatesManager.WarpDirection.UP:
			_on_warp = true
			pos_player.position = Vector2(0,(shape.shape as RectangleShape2D).size.y - (player.collision.shape as RectangleShape2D).size.y)
		
		if _on_warp:
			player.states.set_state("warp")
			player.states.warp_direction = warp_direction
			player.global_position = pos_player.global_position
			player.z_index = -99
			Audio.play_sound(warping_sound, self, false)
	
	if !_on_warp: return
	
	if _duration < _target:
		player.global_position += Vector2.DOWN.rotated(global_rotation) * warping_speed * delta
		_duration += delta
	elif target && !warp_trans:
		if warp_path: 
			warp_trans = WarpTrans.new(player, warp_path, warp_path_speed)
			warp_path.add_child(warp_trans)
			await warp_trans.done
		
		_on_warp = false
		_duration = 0
		target.pass_player(player)
		player = null
		warp_trans = null


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


func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint(): return
	if body == Thunder._current_player: player = body

func _on_body_exited(body: Node2D) -> void:
	if Engine.is_editor_hint(): return
	if body == Thunder._current_player && !_on_warp: player = null


class WarpTrans extends PathFollow2D:
	var player: Player
	var path: Path2D
	var speed: float
	
	signal done
	
	
	func _init(new_player: Player, new_path: Path2D, new_speed: float) -> void:
		loop = false
		progress_ratio = 0
		player = new_player
		path = new_path
		speed = new_speed
		player.visible = false
	
	func _physics_process(delta: float) -> void:
		progress += speed * delta
		player.global_position = global_position
		if progress_ratio >= 1:
			done.emit()
			player.visible = true
			free()
