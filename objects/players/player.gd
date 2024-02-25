extends GravityBody2D
class_name Player

signal suit_appeared
signal suit_changed(to: PlayerSuit)
signal swam
signal shot
signal invinciblized(dur: float)
signal starmaned(dur: float)
signal damaged
signal died

enum Warp {
	NONE,
	IN,
	OUT,
}

enum WarpDir {
	LEFT,
	RIGHT,
	UP,
	DOWN
}

@export_group("General")
@export var nickname: StringName = &"MARIO"
@export var character: StringName = &"Mario"
@export_group("Suit")
@export var suit: PlayerSuit = preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_small.tres"):
	set(to):
		if (!to || suit.name == to.name) && !_force_suit: return
		suit = to.duplicate()
		
		if suit.animation_sprites:
			sprite.sprite_frames = suit.animation_sprites
		
		_physics_behavior = null
		_suit_behavior = null
		_animation_behavior = null
		_extra_behavior = null
		if suit.physics_behavior:
			_physics_behavior = ByNodeScript.activate_script(suit.physics_behavior, self)
		if suit.behavior_script:
			_suit_behavior = ByNodeScript.activate_script(suit.behavior_script, self, {suit_resource = suit.behavior_resource})
		if suit.animation_behavior:
			_animation_behavior = ByNodeScript.activate_script(suit.animation_behavior, self)
		if suit.extra_behavior:
			_extra_behavior = ByNodeScript.activate_script(suit.extra_behavior, self, suit.extra_vars)
		if _suit_appear:
			_suit_appear = false
			suit_appeared.emit()
		Thunder._current_player_state = suit
		suit_changed.emit(suit)
@export_group("Physics")
@export_enum("Left: -1", "Right: 1") var direction: int = 1:
	set(to):
		direction = to
		if !direction in [-1, 1]:
			direction = [-1, 1].pick_random()
@export_group("Death", "death_")
@export var death_sprite: Node2D
@export var death_body: PackedScene = preload("res://engine/objects/players/deaths/player_death.tscn")
@export var death_music_override: AudioStream
@export var death_wait_time: float = 3.5
@export var death_check_for_lives: bool = true
@export var death_stop_music: bool = true

var _physics_behavior: ByNodeScript
var _suit_behavior: ByNodeScript
var _animation_behavior: ByNodeScript
var _extra_behavior: ByNodeScript

var left_right: int
var up_down: int
var jumping: int
var jumped: bool
var running: bool
var attacked: bool
var attacking: bool
var slided: bool

@warning_ignore("unused_private_class_variable")
var _has_jumped: bool

var is_climbing: bool
var is_sliding: bool
var is_crouching: bool
var is_underwater: bool
var is_underwater_out: bool

var completed: bool

var warp: Warp
var warp_dir: WarpDir

var _force_suit: bool
var _suit_appear: bool

@warning_ignore("unused_private_class_variable")
@onready var _is_ready: bool = true

@onready var control: PlayerControl = PlayerControl.new()

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body: ShapeCast2D = $Body
@onready var head: ShapeCast2D = $Head
@onready var underwater: Node = $Underwater
@onready var timer_invincible: Timer = $Invincible
@onready var timer_starman: Timer = $Starman
@onready var attack: ShapeCast2D = $Attack

@onready var starman_combo: Combo = Combo.new(self)


func _ready() -> void:
	# Transition center at the beginning of the level
	Scenes.scene_ready.connect(func():
		var cam := Thunder._current_camera
		if cam:
			cam.force_update_scroll()
		
		for i in 8: # Deferred 8 frames to ensure the transition works after the player touches checkpoint
			await get_tree().process_frame
		
		var trans := TransitionManager.current_transition
		if is_instance_valid(trans):
			trans.on(self)
			trans.paused = false
	, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	
	if !Thunder._current_player_state:
		Thunder._current_player_state = suit
	else:
		suit = Thunder._current_player_state
	
	change_suit(suit, false, true)
	
	Thunder._current_player = self
	
	if !is_starman():
		sprite.material.set_shader_parameter(&"mixing", false)
	
	if Data.values.lives == -1 && death_check_for_lives:
		Data.values.lives = ProjectSettings.get_setting("application/thunder_settings/player/default_lives", 4)


var _starman_faded: bool

func _physics_process(delta: float) -> void:
	if !Thunder._current_player_state:
		Thunder._current_player_state = suit
	if is_starman && (
		timer_starman.time_left > 0.0 &&
		timer_starman.time_left < 1.5 &&
		!_starman_faded
	):
		_starman_faded = true
		Audio.stop_music_channel(98, true)


func change_suit(to: PlayerSuit, appear: bool = true, forced: bool = false) -> void:
	_force_suit = forced
	_suit_appear = appear
	suit = to
	_force_suit = false
	_suit_appear = false


func control_process() -> void:
	left_right = int(Input.get_axis(control.left, control.right))
	up_down = int(Input.get_axis(control.up, control.down))
	jumping = int(Input.is_action_pressed(control.jump)) \
		+ int(Input.is_action_just_pressed(control.jump))
	jumped = Input.is_action_just_pressed(control.jump)
	running = Input.is_action_pressed(control.run)
	attacked = Input.is_action_just_pressed(control.attack)
	attacking = Input.is_action_pressed(control.attack)
	is_crouching = Input.is_action_pressed(control.down) \
		&& is_on_floor() && suit && suit.physics_crouchable && !is_sliding
	slided = Input.is_action_pressed(control.down) \
		&& is_on_floor() && abs(rad_to_deg(get_floor_normal().x)) > 39


#= Status
func invincible(duration: float = 2) -> void:
	timer_invincible.start(duration)
	invinciblized.emit(duration)


func starman(duration: float = 10) -> void:
	invincible(duration)
	sprite.material.set_shader_parameter(&"mixing", true)
	attack.enabled = true
	timer_starman.start(duration)
	starmaned.emit(duration)


func hurt(tags: Dictionary = {}) -> void:
	if !suit:
		return
	if !tags.get(&"hurt_forced", false) && (is_invincible() || completed || warp > Warp.NONE):
		return
	if warp != Warp.NONE: return
	
	if suit.gets_hurt_to:
		change_suit(suit.gets_hurt_to)
		invincible(tags.get(&"hurt_duration", 2))
		Audio.play_sound(suit.sound_hurt, self, false, {pitch = suit.sound_pitch})
	else:
		die(tags)
	
	damaged.emit()


var is_dying: bool = false
func die(tags: Dictionary = {}) -> void:
	if warp != Warp.NONE: return
	if is_dying: return
	is_dying = true
	
	if death_stop_music:
		Audio.stop_all_musics()
	Audio.play_music(
		suit.sound_death if !death_music_override else death_music_override,
		1 if death_stop_music else 2,
		{pitch = suit.sound_pitch}
	)
	
	if death_body:
		NodeCreator.prepare_2d(death_body, self).bind_global_transform().call_method(
			func(db: Node2D) -> void:
				db.wait_time = death_wait_time
				db.check_for_lives = death_check_for_lives
				if death_sprite:
					var dsdup: Node2D = death_sprite.duplicate()
					db.add_child(dsdup)
					dsdup.visible = true
		).create_2d()
	
	died.emit()
	queue_free()


func is_invincible() -> bool:
	return !timer_invincible.is_stopped()


func is_starman() -> bool:
	return !timer_starman.is_stopped()


func _on_starman_timeout() -> void:
	starman_combo.reset_combo()
	sprite.material.set_shader_parameter(&"mixing", false)
	attack.enabled = is_sliding
	_starman_faded = false
	var mus_loader = Scenes.current_scene.get_node_or_null("MusicLoader")
	if mus_loader:
		if mus_loader.is_paused:
			mus_loader.play_immediately = true
			mus_loader.unpause_music()
		elif !mus_loader.buffer.is_empty():
			mus_loader.play_immediately = true
			mus_loader.play_buffered()
			print("Played buffered")


func _on_starman_killed(what: Node, result: Dictionary) -> void:
	if what == self: return
	# Combo
	if result.result:
		if !starman_combo.get_combo() <= 0:
			what.sound_pitch = 1 + starman_combo.get_combo() * 0.135
		#what.got_killed(&"starman", [&"no_score"])
		starman_combo.combo()

