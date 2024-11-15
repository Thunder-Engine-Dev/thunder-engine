extends Area2D

@export var sprite_frames: SpriteFrames = preload("res://engine/objects/warps/door/door_animation.tres")
@export_category("Warp")
@export_node_path("Area2D") var warp_to: NodePath
@export var warping_sound: AudioStream = preload("res://engine/objects/players/prefabs/sounds/door.wav")
@export var warp_to_scene: String
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

var _on_warp: bool
var _duration: float
var _target: float = 0.8
var _warp_triggered: bool = false

@onready var target: Area2D = get_node_or_null(warp_to)
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_bg: Sprite2D = $SpriteBG
@onready var pos_player: Marker2D = $PosPlayer

signal player_enter
signal player_exit
signal warp_started
signal warped

func _ready() -> void:
	$AnimatedSprite2D.sprite_frames = sprite_frames

func _physics_process(delta: float) -> void:
	if !player: return
	
	var input_y: int = int(Input.get_axis(player.control.up, player.control.down))
	
	if player.is_on_floor() && !_on_warp && player.warp == Player.Warp.NONE && \
	!(&"holding" in player.suit.extra_vars && player.suit.extra_vars.is_holding) && \
	player.global_position.y <= pos_player.global_position.y + 8:
		if input_y < 0:
			_on_warp = true
			#pos_player.position = Vector2(0, (shape.shape as RectangleShape2D).size.y - (player.collision_shape.shape as RectangleShape2D).size.y + 16)
		
		if _on_warp:
			sprite.z_index = 1
			sprite.play(&"open")
			sprite_bg.z_index = 1
			sprite_bg.visible = true
			warp_started.emit()
			
			player.warp = Player.Warp.IN
			@warning_ignore("int_as_enum_without_cast")
			player.warp_dir = int(player.direction > 0)
			player.global_position = pos_player.global_position
			player.speed = Vector2.ZERO
			Audio.play_sound(warping_sound, self, false)
			Thunder._current_hud.timer.paused = true
	
	if !_on_warp: return
	
	if _duration < _target:
		player.global_position = pos_player.global_position
		player.sprite.play(&"default")
		_duration += delta
	
	# Warping Transition
	elif !_warp_triggered:
		_warp_triggered = true
		
		if use_circle_transition:
			_circle_transition()
		
		elif use_blur_transition:
			var trans = load(
				"res://engine/components/transitions/blur_transition/blur_transition.tscn"
			).instantiate()
			trans.speed_closing = blur_closing_speed
			trans.speed_opening = -blur_opening_speed
			
			TransitionManager.accept_transition(trans)
			await TransitionManager.transition_middle
			TransitionManager.current_transition.paused = true
			
			pass_warp()
			await get_tree().physics_frame
			
			if warp_to_scene: 
				Scenes.scene_changed.connect(func(_current_scene):
					TransitionManager.current_transition.paused = false
				, CONNECT_ONE_SHOT)
			else:
				TransitionManager.current_transition.paused = false
		else: pass_warp()


func _circle_transition() -> void:
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
			if !Thunder._current_player:
				TransitionManager.current_transition.paused = false
		, CONNECT_ONE_SHOT)
	else:
		if circle_center_after_middle:
			TransitionManager.current_transition.on(Vector2(0.5, 0.5), true)
		TransitionManager.current_transition.paused = false

	pass_warp.call_deferred()


func pass_warp() -> void:
	warped.emit()
	sprite.animation = &"default"
	sprite.z_index = 0
	sprite_bg.z_index = 0
	sprite_bg.visible = false
	_on_warp = false
	_warp_triggered = false
	_duration = 0
	if target:
		target.pass_player(player)
		target.sprite.z_index = 10
		target.sprite_bg.z_index = 1
		target.sprite_bg.visible = true
	elif warp_to_scene:
		Scenes.goto_scene(warp_to_scene)
	player = null


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


func _on_animation_finished() -> void:
	if !sprite: return
	if sprite.animation == &"open":
		sprite.z_index = 10
		sprite_bg.z_index = 1
		sprite.play(&"close")
