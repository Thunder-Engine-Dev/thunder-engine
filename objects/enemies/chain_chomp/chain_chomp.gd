extends GravityBody2D

signal chain_disconnected

const CHAIN: PackedScene = preload("./chain_chomp_chain.tscn")
const PILE: PackedScene = preload("./chain_chomp_pile.tscn")

@export_category("Chain Chomp")
@export var chain_amount: int = 5
@export_group("Walking", "walking_")
@export var walking_range: float = 64
@export var walking_rest_duration: float = 1.5
@export var walking_jump_speed: float = 150
@export_group("Attacking", "attacking_")
@export var attacking_range: float = 128
@export var attacking_speed: float = 650
@export var attacking_preparation_duration: float = 1.0
@export var attacking_rest_duration: float = 0.9
@export var attacking_sound: AudioStream = preload("res://modules/te-chain-chomp/sound/chain_chomp_barking.wav")
@export var attacking_barking_times: int = 6

var dir: int
var step: int

var pile_pos_x: float
var pos_to_attack: Vector2
var pos_when_attack: Vector2

var tween: Tween

var _is_ready: bool
var _rest: SceneTreeTimer

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	var spd: float = speed.x
	vel_set_x(0)
	
	await get_tree().physics_frame
	_is_ready = true
	
	var pile: Node2D = NodeCreator.prepare_2d(PILE, self).bind_global_transform().create_2d().get_node()
	pile.z_index = -2
	pile_pos_x = global_transform.affine_inverse().basis_xform(pile.global_position).x
	add_collision_exception_with(pile)
	
	for i: int in chain_amount:
		var chain: RigidBody2D = NodeCreator.prepare_2d(CHAIN, self).bind_global_transform().create_2d().get_node()
		chain.chomp = self
		chain.pile = pile
		chain.add_collision_exception_with(pile)
		chain.id = i
		chain.z_index = -1
		chain.amount = chain_amount
		chain_disconnected.connect(chain.disconnect_chomp)
	
	_dir()
	vel_set_x(dir * spd)


func _physics_process(delta: float) -> void:
	if !_is_ready: return
	
	var player: Player = Thunder._current_player
	
	match step:
		0:
			_walk()
			if player && player.global_position.distance_squared_to(global_position) < attacking_range ** 2:
				step = 1
			motion_process(delta)
		1:
			_dir()
			_attacking_pre(player)
		2:
			_attacking_process()
	
	if dir != 0: sprite.flip_h = (dir < 0)


func _dir() -> void:
	var player: Player = Thunder._current_player
	if !player: return
	dir = Thunder.Math.look_at(global_position, player.global_position, global_transform)


func _walk() -> void:
	if speed.x != 0: 
		dir = int(signf(speed.x))
	
	var posx: float = global_transform.affine_inverse().basis_xform(global_position).x
	if is_on_wall() || (!_rest && ((dir < 0 && posx < pile_pos_x - walking_range) || (dir > 0 && posx > pile_pos_x + walking_range))):
		var speed_x: float = speed.x
		
		vel_set_x(0)
		_rest = get_tree().create_timer(walking_rest_duration, false, true)
		
		await _rest.timeout
		
		vel_set_x(-speed_x)
		_rest = null
	
	if is_on_floor(): jump(walking_jump_speed)


func _attacking_pre(player: Player) -> void:
	if step != 1: return
	await get_tree().create_timer(attacking_preparation_duration, false, true).timeout
	pos_when_attack = global_position
	if is_instance_valid(player): pos_to_attack = player.global_position
	step = 2


func _attacking_process() -> void:
	if step != 2: return
	if tween: return
	var to: Vector2 = pos_when_attack + (pos_to_attack - pos_when_attack).limit_length(attacking_range)
	tween = create_tween()
	tween.tween_callback(func() -> void:
		sprite.speed_scale = 3
	)
	tween.tween_property(self, "global_position", to, pos_to_attack.distance_to(pos_when_attack) / attacking_speed)
	for i in attacking_barking_times:
		tween.tween_callback(func() -> void:
			Audio.play_sound(attacking_sound, self, false)
		)
		tween.tween_interval(attacking_rest_duration / attacking_barking_times)
	tween.tween_property(self, "global_position", pos_when_attack, pos_to_attack.distance_to(pos_when_attack) / attacking_speed)
	tween.tween_callback(func() -> void:
		sprite.speed_scale = 1
		step = 0
		tween.kill()
		tween = null
	)


func _on_killed_succeeded() -> void:
	chain_disconnected.emit()
