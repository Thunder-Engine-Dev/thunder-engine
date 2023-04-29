extends GravityBody2D
class_name PlayerMario

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
@export_group("Physics")
@export_enum("Left: -1", "Right: 1") var direction: int = 1:
	set(to):
		direction = to
		if !direction in [-1, 1]:
			direction = [-1, 1].pick_random()

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

var _force_suit: bool
var _suit_appear: bool

@onready var _is_ready: bool = true

@onready var control: PlayerControl = PlayerControl.new()

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body: ShapeCast2D = $Body
@onready var head: ShapeCast2D = $Head
@onready var underwater: Node = $Underwater


func _ready() -> void:
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
