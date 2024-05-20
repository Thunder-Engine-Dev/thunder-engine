extends GeneralMovementBody2D

@export var spring_jump_height: float = 975

@onready var enemy_attacked: Node = $Body/EnemyAttacked

@onready var animation_node: Node2D = $Node2D
@onready var marker: Node2D = $Node2D/Marker2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Node2D/Timer

var is_better: bool
var is_triggered: bool
var is_playing_backwards: bool
var is_higher: bool

var old_config: PlayerConfig
var player: Player

func _ready() -> void:
	if SettingsManager.get_tweak("better_springboards"):
		is_better = true
		var spr = get_node(sprite) as AnimatedSprite2D
		spr.visible = false
		animation_node.visible = true
		animation_player.animation_finished.connect(_animation_finished)
		enemy_attacked.stomping_enabled = false
		#timer.timeout.connect(func():
		#	enemy_attacked.stomping_enabled = true
		#)
		return
	
	animation_node.queue_free()


func _physics_process(delta: float) -> void:
	if !is_triggered: return
	if player:
		#player.no_movement = true
		player.global_position.y = marker.global_position.y - 16
		player.speed.y = 0


func trigger(pl: Player = null) -> void:
	if !is_better:
		var spr = get_node(sprite) as AnimatedSprite2D
		spr.play(&"default")
		spr.frame = 0
		return
	
	if !is_instance_valid(pl): return
	if !timer.is_stopped(): return
	if is_triggered: return
	timer.start()
	
	animation_player.play(&"jump")
	player = pl
	_add_config(pl)


func _animation_finished(anim: String) -> void:
	if !is_triggered: return
	if !is_playing_backwards:
		animation_player.play(&"jump", -1, -2.0, true)
		enemy_attacked._lss()
		is_playing_backwards = true
	else:
		is_playing_backwards = false
		is_triggered = false
		if player:
			_reset_config(player)
			#player.no_movement = false
			player.speed.y = -spring_jump_height if is_higher else -enemy_attacked.stomping_player_jumping_min
			player = null
		is_higher = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("m_jump"):
		if is_better && player == Thunder._current_player:
			if is_triggered:
				is_higher = true
				player._has_jumped = true
				player.speed.y = 0
			return
		enemy_attacked.stomping_player_jumping_max = spring_jump_height
		await get_tree().create_timer(0.1).timeout
		enemy_attacked.stomping_player_jumping_max = enemy_attacked.stomping_player_jumping_min


func _add_config(_player) -> void:
	if !_player: return
	old_config = _player.suit.physics_config
	_player.suit.physics_config = old_config.duplicate(false)
	
	_player._has_jumped = true
	_player.speed.x /= 2
	#_player.suit.physics_config.walk_acceleration = 0
	_player.suit.physics_config.walk_max_walking_speed /= 2
	_player.suit.physics_config.walk_max_running_speed /= 2
	is_triggered = true


func _reset_config(_player) -> void:
	if !_player: _player = Thunder._current_player
	if !is_instance_valid(_player): return
	if !old_config: return
	
	_player.speed.x *= 2
	_player.suit.physics_config = old_config
	#_player.suit.physics_config.walk_acceleration = old_config.walk_acceleration
	_player.suit.physics_config.walk_max_walking_speed = old_config.walk_max_walking_speed
	_player.suit.physics_config.walk_max_running_speed = old_config.walk_max_running_speed
