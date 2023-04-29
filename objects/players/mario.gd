extends Player
class_name Mario

signal suit_appeared
signal swam
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
@export_group("Suit")
@export var suit: MarioSuit = preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_small.tres"):
	set(to):
		if (!to || suit == to) && !_force_suit: return
		suit = to.duplicate(true)
		if suit.animation_behavior:
			_animation_behavior = ByNodeScript.activate_script(suit.animation_behavior, self)
		if suit.physics_behavior:
			_physics_behavior = ByNodeScript.activate_script(suit.physics_behavior, self)
		if suit.behavior_script:
			_suit_behavior = ByNodeScript.activate_script(suit.behavior_script, self)
		if suit.extra_behavior:
			_extra_behavior = ByNodeScript.activate_script(suit.extra_behavior, self, suit.extra_vars)
		if _suit_appear:
			_suit_appear = false
			suit_appeared.emit()
@export_group("Physics")
@export_enum("Left: -1", "Right: 1") var direction: int = 1:
	set(to):
		direction = to
		if !direction in [-1, 1]:
			direction = [-1, 1].pick_random()
@export_group("Death", "death_")
@export var death_sprite: Node2D
@export var death_body: PackedScene = preload("res://engine/objects/players/deaths/player_death.tscn")

var _animation_behavior: ByNodeScript
var _physics_behavior: ByNodeScript
var _suit_behavior: ByNodeScript
var _extra_behavior: ByNodeScript

var left_right: int
var jumping: int
var jumped: bool
var running: bool
var attacked: bool
var attacking: bool

var is_crouching: bool
var is_underwater: bool
var is_underwater_out: bool

var warp: Warp
var warp_dir: WarpDir

var _force_suit: bool
var _suit_appear: bool

@onready var _is_ready: bool = true

@onready var control: PlayerControl = PlayerControl.new()

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body: ShapeCast2D = $Body
@onready var head: ShapeCast2D = $Head
@onready var underwater: Node = $Underwater
@onready var timer_invincible: Timer = $Invincible
@onready var timer_starman: Timer = $Starman


func _ready() -> void:
	if !Thunder._current_player_state:
		Thunder._current_player_state = suit
	else:
		suit = Thunder._current_player_state
	change_suit(suit, false, true)


func change_suit(to: MarioSuit, appear: bool = true, forced: bool = false) -> void:
	_force_suit = forced
	_suit_appear = appear
	suit = to
	_force_suit = false
	_suit_appear = false


func control_process() -> void:
	left_right = int(Input.get_axis(control.left, control.right))
	jumping = int(Input.is_action_pressed(control.jump)) + int(Input.is_action_just_pressed(control.jump))
	jumped = Input.is_action_just_pressed(control.jump)
	running = Input.is_action_pressed(control.run)
	attacked = Input.is_action_just_pressed(control.jump)
	attacking = Input.is_action_pressed(control.jump)
	is_crouching = Input.is_action_pressed(control.down) && is_on_floor()


#= Status
func invincible(duration: float = 2) -> void:
	timer_invincible.start(duration)


func starman(duration: float = 10) -> void:
	invincible(duration)
	timer_starman.start(duration)


func hurt(tags: Dictionary = {}) -> void:
	if !suit:
		return
	if !tags.get(&"hurt_forced", false) && is_invincible():
		return
	if suit.gets_hurt_to:
		suit = suit.gets_hurt_to
		invincible(tags.get(&"hurt_duration", 2))
		Audio.play_sound(suit.sound_hurt, self, false, {pitch = suit.sound_pitch})
	else:
		die(tags)


func die(tags: Dictionary = {}) -> void:
	Audio.play_music(suit.sound_death, 1, {pitch = suit.sound_pitch})
	
	if death_body:
		NodeCreator.prepare_2d(death_body, self).bind_global_transform().call_method(
			func(db: Node2D) -> void:
				if death_sprite:
					var dsdup: Node2D = death_sprite.duplicate()
					db.add_child(dsdup)
					dsdup.visible = true
		).create_2d()
	
	queue_free()


func is_invincible() -> bool:
	return !timer_invincible.is_stopped()


func is_starman() -> bool:
	return !timer_starman.is_stopped()