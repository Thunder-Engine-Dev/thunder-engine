@icon("res://engine/objects/warps/icons/pipe_in.svg")
@tool
extends Area2D

@export_category("Warp")
@export_group("Editor","warping_editor_")
@export var warping_editor_display_path: bool = true
@export var warping_editor_color: Color = Color(0.5,1,0.3,0.6)
@export_group("General")
@export var warp_direction: Player.WarpDir = Player.WarpDir.DOWN
@export_node_path("Area2D") var warp_to: NodePath
@export_file("*.tscn", "*.scn") var warp_to_scene: String
@export var trigger_finish: bool = false
@export var warping_speed: float = 60
@export var warping_sound: AudioStream = preload("res://engine/objects/players/prefabs/sounds/pipe.wav")
@export_group("Tweaks")
@export var warp_invisible_left_right: bool = true
@export var warp_disable_smooth_entry: bool = false
@export_group("Path Transition")
@export var warp_path: Path2D
@export var warp_path_speed: float = 400
@export_group("Circle Transition")
@export var use_circle_transition: bool = false
@export var circle_closing_speed: float = 0.1
@export var circle_opening_speed: float = 0.1
@export var circle_focus_on_player: bool = true
@export var circle_center_after_middle: bool = false
@export var circle_wait_till_scene_changed: bool = true
@export_group("Crossfade Transition")
@export var force_circle_instead_of_crossfade: bool = false
@export var crossfade_fade_speed: float = 0.54
@export_group("Blur Transition")
@export var use_blur_transition: bool = false
@export var blur_closing_speed: float = 2.2
@export var blur_opening_speed: float = 2.2

var player: Player
var player_z_index: int
var warp_trans: WarpTrans

var _on_warp: bool
var _duration: float
var _target: float = 1.2
var _warp_triggered: bool = false

@onready var target: Area2D = get_node_or_null(warp_to)
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var pos_player: Marker2D = $PosPlayer
@onready var pos_player_invisible = $PosPlayerInvisible

signal player_enter
signal player_exit
signal warp_started
signal warp_ended

func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	$Arrow.queue_free()
	$TextDir.queue_free()


func _draw() -> void:
	if !Engine.is_editor_hint(): return
	
	draw_set_transform(Vector2.ZERO, -global_rotation, Vector2.ONE / global_scale)
	
	var tg:Area2D = get_node_or_null(warp_to)
	if !tg: return
	if !tg.is_in_group("pipe_out"):
		printerr(name, 
			""": warp_to contains a path to an invalid warp scene. Property has been reset."""
		)
		warp_to = ""
		return
	
	if !warping_editor_display_path: return
	draw_line(Vector2.ZERO,tg.global_position - global_position, warping_editor_color,4)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		_label()
		return
	if !player: return
	
	var input_x: int = player.left_right
	var input_y: int = player.up_down
	
	if !_on_warp && player.warp == Player.Warp.NONE:
		if input_x > 0 && warp_direction == Player.WarpDir.RIGHT && player.is_on_floor():
			_on_warp = true
			pos_player.position = Vector2(-(shape.shape as RectangleShape2D).size.x / 2, 0)
		elif input_x < 0 && warp_direction == Player.WarpDir.LEFT && player.is_on_floor():
			_on_warp = true
			pos_player.position = Vector2((shape.shape as RectangleShape2D).size.x / 2, 0)
		if input_y > 0 && warp_direction == Player.WarpDir.DOWN:
			_on_warp = true
			pos_player.position = Vector2(0, 0)
		elif input_y < 0 && warp_direction == Player.WarpDir.UP:
			_on_warp = true
			pos_player.position = Vector2(0, (shape.shape as RectangleShape2D).size.y - (player.collision_shape.shape as RectangleShape2D).size.y + 16)
		
		if _on_warp:
			player_z_index = player.z_index
			
			warp_started.emit()
			player.warp = Player.Warp.IN
			player.warp_dir = warp_direction
			if !warp_disable_smooth_entry:
				var pos_tw = create_tween()
				pos_tw.tween_property(player, "global_position", pos_player.global_position, 0.1)
			else:
				player.global_position = pos_player.global_position
			player.z_index = -5
			player.speed = Vector2.ZERO
			if is_instance_valid(Thunder._current_camera):
				Thunder._current_camera.teleport()
			Audio.play_sound(warping_sound, self, false)
			Thunder._current_hud.timer.paused = true
	
	if !_on_warp: return
	
	if _duration < _target:
		player.global_position += Vector2.DOWN.rotated(global_rotation) * warping_speed * delta
		_duration += delta
		_tweak_process()
	
	# Warping Transition
	elif !warp_trans && !_warp_triggered:
		_warp_triggered = true
		warp_ended.emit()
		
		if use_circle_transition:
			var _crossfades: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)
			if warp_to_scene && !force_circle_instead_of_crossfade && _crossfades:
				pass_warp()
				TransitionManager.accept_transition(
					load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
						.instantiate()
						.with_time(crossfade_fade_speed)
						.with_scene(warp_to_scene)
				)
				warp_to_scene = ""
				return
			TransitionManager.accept_transition(
				load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
					.instantiate()
					.with_speeds(circle_closing_speed, -circle_opening_speed)
					.on_player_after_middle(circle_focus_on_player && !circle_center_after_middle)
			)
			if circle_focus_on_player: TransitionManager.current_transition.on(Thunder._current_player)
			await TransitionManager.transition_middle
			
			TransitionManager.current_transition.paused = true
			
			if warp_to_scene && circle_wait_till_scene_changed:
				Scenes.scene_ready.connect(func():
					TransitionManager.current_transition.paused = false
				, CONNECT_ONE_SHOT)
			else:
				if circle_center_after_middle:
					TransitionManager.current_transition.on(Vector2(0.5, 0.5), true)
				TransitionManager.current_transition.paused = false
			
			pass_warp.call_deferred()
			
		elif use_blur_transition:
			var trans = load(
				"res://engine/components/transitions/blur_transition/blur_transition.tscn"
			).instantiate()
			trans.speed_closing = blur_closing_speed
			trans.speed_opening = -blur_opening_speed
			
			TransitionManager.accept_transition(trans)
			await TransitionManager.transition_middle
			
			# The commented code needs fixing and is temporarily commented out
			
			#TransitionManager.current_transition.paused = true
			
			
			#if warp_to_scene: 
			#	Scenes.scene_changed.connect(func(_current_scene):
			#		TransitionManager.current_transition.paused = false
			#	, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
			#else:
			#	TransitionManager.current_transition.paused = false
			
			await get_tree().physics_frame
			pass_warp()
		else: pass_warp()


func pass_warp() -> void:
	if target && warp_path: 
		warp_trans = WarpTrans.new(player, warp_path, warp_path_speed)
		warp_path.add_child(warp_trans)
		await warp_trans.done
	
	_on_warp = false
	_warp_triggered = false
	_duration = 0
	if target:
		target.pass_player(player)
		target.player_z_index = player_z_index
		target.warp_invisible_left_right = warp_invisible_left_right
		_transition_update()
	elif warp_to_scene:
		Scenes.goto_scene(warp_to_scene)
	elif trigger_finish:
		Scenes.current_scene.finish(true)
		player.modulate.a = 0
	player = null
	warp_trans = null


func _tweak_process() -> void:
	if !warp_invisible_left_right: return
	
	if warp_direction == Player.WarpDir.RIGHT && player.global_position.x > pos_player_invisible.global_position.x:
		player.sprite.visible = false
	if warp_direction == Player.WarpDir.LEFT && player.global_position.x < pos_player_invisible.global_position.x:
		player.sprite.visible = false


func _transition_update() -> void:
	if use_circle_transition && circle_focus_on_player:
		await get_tree().process_frame
		await get_tree().process_frame
		TransitionManager.current_transition.on(Thunder._current_player)


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


func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint(): return
	if body == Thunder._current_player:
		player = body
		player_enter.emit()

func _on_body_exited(body: Node2D) -> void:
	if Engine.is_editor_hint(): return
	if body == Thunder._current_player && !_on_warp:
		player = null
		player_exit.emit()


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
			queue_free()
