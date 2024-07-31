extends GeneralMovementBody2D

const Shell: Script = preload("./koopa_shell.gd")

@export_category("KoopaShell")
@export var stopping: bool = true
@export var restoring_damage_delay: float = 0.6
@export_group("Breaking")
@export_range(0, 64, 1, "or_greater") var max_multiple_breaking_blocks: int = 32
@export_group("Attack")
@export_range(0, 256) var sharpness: int
@export_group("Sound", "sound_")
@export var kicked_sound: AudioStream = preload("res://engine/objects/players/prefabs/sounds/kick.wav")
@export var combo_sound: AudioStream = preload("res://engine/objects/players/prefabs/sounds/kick.wav")

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
			enemy_attacked.set_meta(
				&"attacker_speed", target_enemy_attacked.owner.speed
			)
			enemy_attacked.got_killed(&"shell_forced")
			target_enemy_attacked.set_meta(&"attacker_speed", speed)
			target_enemy_attacked.got_killed(&"shell_forced")
	# Combo
	elif result.result && sharpness >= target_enemy_attacked.killing_immune.shell_defence:
		if !combo.get_combo() <= 0:
			target_enemy_attacked.sound_pitch = 1 + combo.get_combo() * 0.135
		target_enemy_attacked.set_meta(&"attacker_speed", speed)
		target_enemy_attacked.got_killed(&"shell_forced", [&"no_score"])
		combo.combo()
	# Gets blocked
	else:
		if &"speed" in target_enemy_attacked.owner:
			enemy_attacked.set_meta(
				&"attacker_speed", target_enemy_attacked.owner.speed
			)
		enemy_attacked.got_killed(&"shell_forced")


func _on_body_entered(player: Node2D) -> void:
	if !stopping: return
	if player != Thunder._current_player: return
	if Thunder._current_player.warp > Player.Warp.NONE: return
	if is_instance_valid(_delayer) || enemy_attacked.get_stomping_delayer(): return
	status_swap(false)
	sound()


var _already_processed: Array[int]

func _on_collided_wall() -> void:
	var dir = 1 if speed.x < 0 else -1
	var saved_pos = global_position
	_process_collision_deferred(dir, saved_pos)

func _process_collision_deferred(dir: int, saved_pos: Vector2) -> void:
	global_position = saved_pos
	var rot: = get_global_gravity_dir().angle()
	var vel = Vector2(dir, 0).rotated(rot - PI/2)
	if is_zero_approx(vel.y):
		vel.y = 0
	
	# WARNING: Only the first collision shape will be considered!
	var query := PhysicsShapeQueryParameters2D.new()
	query.collision_mask = collision_mask
	query.motion = vel * velocity.length()
	query.margin = 0.08
	
	for i in get_shape_owners():
		query.transform = (shape_owner_get_owner(i) as Node2D).global_transform
		for j in shape_owner_get_shape_count(i):
			query.shape = shape_owner_get_shape(i, j)
			
			var cldata: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query, max_multiple_breaking_blocks)
			print(cldata)
			
			for k in cldata:
				var l: Object = k.get(&"collider", null)
				var id: int = k.get(&"collider_id", 0)
				
				if !(id in _already_processed):
					_already_processed.append(id)
					if l is StaticBumpingBlock:
						if l.has_method(&"got_bumped"):
							l.got_bumped.call_deferred(self)
						elif l.has_method(&"bricks_break"):
							l.bricks_break.call_deferred()
