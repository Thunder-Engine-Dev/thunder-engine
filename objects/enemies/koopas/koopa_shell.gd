extends GeneralMovementBody2D

const Shell: Script = preload("./koopa_shell.gd")

@export_category("KoopaShell")
@export var stopping: bool = true
@export var restoring_damage_delay: float = 0.8
@export_subgroup("Attack")
@export_range(0, 256) var sharpness: int
@export_group("Sound", "sound_")
@export var kicked_sound: AudioStream = preload("res://engine/objects/mario/sounds/kick.wav")
@export var combo_sound: AudioStream = preload("res://engine/objects/mario/sounds/kick.wav")

var _delayer: SceneTreeTimer

@onready var combo: Combo = Combo.new(self)

@onready var body: Area2D = $Body
@onready var enemy_attacked: Node = $Body/EnemyAttacked
@onready var animation: AnimatedSprite2D = get_node_or_null(sprite)
@onready var attack: ShapeCast2D = $Attack

@onready var init_speed: float = speed.x
@onready var attack_type: StringName = attack.killer_type


func _ready() -> void:
	super()
	
	_delayer = get_tree().create_timer(0.05, false)
	_delayer.timeout.connect(
		func() -> void:
			_delayer = null
	)
	
	attack.belongs_to = Data.PROJECTILE_BELONGS.PLAYER
	status_update()


func status_update() -> void:
	update_dir()
	vel_set_x(0.0 if stopping else init_speed * -dir)
	body.solid = stopping
	body.turn_back = stopping
	attack.killer_type = &"" if stopping else attack_type
	
	if !stopping:
		animation.play()
		
		_delayer = get_tree().create_timer(restoring_damage_delay, false)
		await _delayer.timeout
		_delayer = null
		
#		enemy_attacked.add_to_group(&"shell")
		enemy_attacked.stomping_enabled = true
		enemy_attacked.stomping_hurtable = true
		
	else:
		animation.stop()
		animation.frame = 0
		
#		enemy_attacked.remove_from_group(&"shell")
		enemy_attacked.stomping_enabled = false
		enemy_attacked.stomping_hurtable = false
		combo.reset_combo()


func status_swap(to: bool) -> void:
	stopping = to
	status_update()


func sound() -> void:
	Audio.play_sound(kicked_sound, self)


func _on_killing(target_enemy_attacked: Node, result: Dictionary) -> void:
	if target_enemy_attacked == enemy_attacked: return
	# Shells crashing with each other
	if is_instance_of(target_enemy_attacked.owner, Shell) && \
		!target_enemy_attacked.owner.stopping && \
		sharpness <= target_enemy_attacked.killing_immune.shell_defence:
			enemy_attacked.got_killed(&"shell_forced")
	# Combo
	elif result.result && sharpness >= target_enemy_attacked.killing_immune.shell_defence:
		if !combo.get_combo() <= 0:
			target_enemy_attacked.sound_pitch = 1 + combo.get_combo() * 0.135
		target_enemy_attacked.got_killed(&"shell_forced", [&"no_score"])
		combo.combo()
	# Gets blocked
	else:
		enemy_attacked.got_killed(&"shell_forced")


func _on_body_entered(player: Node2D) -> void:
	if !stopping: return
	if player != Thunder._current_player: return
	if Thunder._current_player.states.current_state == "warp": return
	if is_instance_valid(_delayer) || enemy_attacked.get_stomping_delayer(): return
	status_swap(false)
	sound()
