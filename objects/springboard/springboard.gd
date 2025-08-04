extends GeneralMovementBody2D

const LENIENCY_AFTER_BOUNCE_SEC: float = 0.14

@export var spring_jump_height: float = 975

@onready var enemy_attacked: Node = $Body/EnemyAttacked

@onready var animation_node: Node2D = $Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var can_coyote = SettingsManager.get_tweak("coyote_time", true)

var is_better: bool
var is_playing_backwards: bool
var leniency_timer: float

func _ready() -> void:
	animation_player.animation_finished.connect(_animation_finished)
	is_better = SettingsManager.get_tweak("better_springboards", false)
	var _custom_sound = CharacterManager.get_sound_replace(enemy_attacked.stomping_sound, enemy_attacked.stomping_sound, "spring_bounce", false)
	if _custom_sound:
		enemy_attacked.stomping_sound = _custom_sound


func trigger(pl = null) -> void:
	var current_player: Player = Thunder._current_player
	if !is_instance_valid(current_player):
		return
	#if current_player.is_on_floor():
	#	return
	sprite_node.play(&"default")
	sprite_node.frame = 0
	current_player._has_jumped = true
	if can_coyote && enemy_attacked.stomping_player_jumping_max == enemy_attacked.stomping_player_jumping_min:
		leniency_timer = LENIENCY_AFTER_BOUNCE_SEC

	if animation_node.visible:
		animation_player.play(&"jump")


func _animation_finished(anim: String) -> void:
	if !is_playing_backwards:
		animation_player.play(&"jump", -1, -2.0, true)
		is_playing_backwards = true
	else:
		is_playing_backwards = false


func _physics_process(delta: float) -> void:
	if leniency_timer:
		leniency_timer = maxf(leniency_timer - delta, 0.0)
	if Input.is_action_just_pressed("m_jump"):
		enemy_attacked.stomping_player_jumping_max = spring_jump_height
		var player: Player = Thunder._current_player
		if player && leniency_timer && player.speed.y < -1:
			player.speed.y = -spring_jump_height
		leniency_timer = 0
		if !is_better:
			get_tree().create_timer(0.14, false).timeout.connect(func():
				enemy_attacked.stomping_player_jumping_max = enemy_attacked.stomping_player_jumping_min
			)
		
	if is_better && !Input.is_action_pressed("m_jump"):
		enemy_attacked.stomping_player_jumping_max = enemy_attacked.stomping_player_jumping_min


func _on_screen_entered() -> void:
	if is_better && Input.is_action_pressed("m_jump"):
		enemy_attacked.stomping_player_jumping_max = spring_jump_height


func _on_screen_exited() -> void:
	enemy_attacked.stomping_player_jumping_max = enemy_attacked.stomping_player_jumping_min
