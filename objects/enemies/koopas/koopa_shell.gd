extends GeneralMovementBody2D

const Shell: Script = preload("./koopa_shell.gd")
const DEFAULT_KICK = preload("res://engine/objects/players/prefabs/sounds/kick.wav")

@export_category("KoopaShell")
@export var stopping: bool = true
@export var restoring_damage_delay: float = 0.6

# ==========================================================
# Resurrection Settings
# ==========================================================
@export var enemy_alive_scene: PackedScene
@export var resurrection_time: float = 5.0
@export var warning_duration: float = 1.5

var _resurrection_elapsed: float = 0.0
var _is_blinking: bool = false
var _blink_time: float = 0.0
# ==========================================================

@export_group("Breaking")
@export_range(0, 64, 1, "or_greater") var max_multiple_breaking_blocks: int = 32
@export_group("Attack")
@export_range(0, 256) var sharpness: int
@export_group("Sound", "sound_")
@export var kicked_sound: AudioStream = DEFAULT_KICK
@export var combo_sound: AudioStream = DEFAULT_KICK

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
	attack.special_tags = attack.special_tags.duplicate()
	attack.special_tags.append(&"shell_sharpness:%d" % sharpness)
	status_update()


func _physics_process(delta: float) -> void:
	super(delta)
	if stopping:
		speed.x = 0
		
		# Deterministic resurrection counter (prevents timer leaks across multiple stomps)
		_resurrection_elapsed += delta
		var warning_start_time: float = max(0.0, resurrection_time - warning_duration)
		
		if _resurrection_elapsed >= warning_start_time:
			_is_blinking = true
			
		if _resurrection_elapsed >= resurrection_time:
			_resurrection_elapsed = 0.0
			_on_resurrection_timeout()
			return
		
		# Handle sprite blinking visual output
		if _is_blinking && animation:
			_blink_time += delta
			if _blink_time >= 0.06:
				animation.visible = !animation.visible
				_blink_time = 0.0


func status_update() -> void:
	update_dir()
	vel_set_x(0.0 if stopping else init_speed * -dir)
	body.solid = stopping
	body.turn_back = stopping
	attack.killer_type = &"" if stopping else attack_type
	
	if !stopping:
		animation.play()
		if animation:
			animation.visible = true
		
		_cancel_resurrection()
		
		_delayer = get_tree().create_timer(restoring_damage_delay, false)
		await _delayer.timeout
		_delayer = null
		
		enemy_attacked.stomping_enabled = true
		enemy_attacked.stomping_hurtable = true
		
	else:
		animation.stop()
		animation.frame = 0
		
		enemy_attacked.stomping_enabled = false
		enemy_attacked.stomping_hurtable = false
		combo.reset_combo()
		
		_start_resurrection()


func status_swap(to: bool) -> void:
	stopping = to
	status_update()


# ==========================================================
# Resurrection Logic
# ==========================================================
func _start_resurrection() -> void:
	_cancel_resurrection()


func _cancel_resurrection() -> void:
	_resurrection_elapsed = 0.0
	_is_blinking = false
	_blink_time = 0.0
	if animation:
		animation.visible = true


func _on_resurrection_timeout() -> void:
	if !stopping: return # Safety check: do not revive if it was just hit/kicked
	
	var spawned_scene: PackedScene = enemy_alive_scene
	
	# Fallback if inspector scene is null or empty
	if spawned_scene && !spawned_scene.can_instantiate():
		spawned_scene = null
		
	if !spawned_scene:
		var target_path: String = ""
		
		# STRATEGY 1: TEXTURE DETECTION (Bypasses @CharacterBody2D & duplication naming errors)
		if animation && animation.sprite_frames && animation.sprite_frames.has_animation(&"default"):
			var frame_texture = animation.sprite_frames.get_frame_texture(&"default", 0)
			
			if frame_texture:
				var texture_path: String = ""
				if frame_texture is AtlasTexture && frame_texture.atlas:
					texture_path = frame_texture.atlas.resource_path.to_lower()
				else:
					texture_path = frame_texture.resource_path.to_lower()
				
				if texture_path.contains("red"):
					target_path = "res://engine/objects/enemies/koopas/koopa_red.tscn"
				elif texture_path.contains("blue"):
					target_path = "res://engine/objects/enemies/koopas/koopa_blue.tscn"
				elif texture_path.contains("yellow"):
					target_path = "res://engine/objects/enemies/koopas/koopa_yellow.tscn"
				elif texture_path.contains("green"):
					target_path = "res://engine/objects/enemies/koopas/koopa_green.tscn"
		
		# STRATEGY 2: SANITIZED DYNAMIC NAME FALLBACK
		if target_path.is_empty() or not ResourceLoader.exists(target_path):
			# Strip '@' symbols generated by Godot runtime nodes
			var raw_node_name: String = name.replace("@", "")
			var clean_koopa_name: String = raw_node_name.to_snake_case().replace("koopa_shell_", "koopa_")
			
			# Strip trailing numbers and underscores added by node duplicates (e.g. koopa_red_2 -> koopa_red)
			while clean_koopa_name.length() > 0 and (clean_koopa_name[-1].is_valid_int() or clean_koopa_name[-1] == "_"):
				clean_koopa_name = clean_koopa_name.left(-1)
				
			target_path = "res://engine/objects/enemies/koopas/%s.tscn" % clean_koopa_name
		
		# Load the matching PackedScene
		if ResourceLoader.exists(target_path):
			spawned_scene = load(target_path) as PackedScene
		else:
			print("[Shell] Could not find resurrection scene at target path: ", target_path)
			_cancel_resurrection()
			return
			
	if !spawned_scene || !spawned_scene.can_instantiate():
		print("[Shell] PackedScene is invalid or empty for: ", name)
		_cancel_resurrection()
		return
		
	# Instantiate the alive enemy
	var alive_enemy = spawned_scene.instantiate() as Node2D
	if alive_enemy:
		get_parent().add_child(alive_enemy)
		alive_enemy.global_position = global_position
		if "dir" in alive_enemy:
			alive_enemy.dir = dir
		
		var turner = alive_enemy.get_node_or_null("Turner") as RayCast2D
		if turner:
			turner.position.x = abs(turner.position.x) * dir
			turner.force_raycast_update()
			
		queue_free()

func sound() -> void:
	var _custom_sound = CharacterManager.get_sound_replace(kicked_sound, DEFAULT_KICK, "kick", true)
	Audio.play_sound(_custom_sound, self)


func _on_killing(target_enemy_attacked: Node, result: Dictionary) -> void:
	if target_enemy_attacked == enemy_attacked: return
	var target_defence = target_enemy_attacked.killing_immune.get(&"shell_defence", 0)
	if is_instance_of(target_enemy_attacked.owner, Shell) && \
		!target_enemy_attacked.owner.stopping && \
		sharpness <= target_defence:
			enemy_attacked.set_meta(
				&"attacker_speed", target_enemy_attacked.owner.speed
			)
			enemy_attacked.got_killed(&"shell_forced")
			target_enemy_attacked.set_meta(&"attacker_speed", speed)
			target_enemy_attacked.got_killed(&"shell_forced")
	elif result.result && sharpness >= target_defence:
		var _can_combo: bool = target_enemy_attacked.killing_can_combo
		if combo.get_combo() > 0 && _can_combo:
			target_enemy_attacked.sound_pitch = combo.get_pitch()
		target_enemy_attacked.set_meta(&"attacker_speed", speed)
		target_enemy_attacked.got_killed(&"shell_forced", [&"no_score"])
		if _can_combo:
			combo.combo()
		else:
			ScoreText.new(str(target_enemy_attacked.killing_scores), target_enemy_attacked._center)
			Data.add_score(target_enemy_attacked.killing_scores)
	elif !target_enemy_attacked.owner.has_meta(&"#no_shell_attack") \
			&& (target_enemy_attacked.killing_immune.has(&"shell") && sharpness < target_defence):
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
	player.ground_kicked.emit()
	status_swap(false)
	sound()


var _already_processed: Array[int]

func _on_collided_wall() -> void:
	var _dir = 1 if speed_previous.x > 0 else -1
	var saved_pos = global_position
	_already_processed.clear()
	_process_collision_deferred(_dir, saved_pos)
	turn_x()


func _process_collision_deferred(_dir: int, saved_pos: Vector2) -> void:
	global_position = saved_pos
	var rot: = get_global_gravity_dir().angle()
	var vel = Vector2(_dir, 0).rotated(rot - PI/2)
	if is_zero_approx(vel.y):
		vel.y = 0
	
	var query := PhysicsShapeQueryParameters2D.new()
	query.collision_mask = collision_mask
	query.motion = vel
	
	for i in get_shape_owners():
		query.transform = (shape_owner_get_owner(i) as Node2D).global_transform
		for j in shape_owner_get_shape_count(i):
			query.shape = shape_owner_get_shape(i, j)
			
			var cldata: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query, max_multiple_breaking_blocks)
			
			for k in cldata:
				var l: Object = k.get(&"collider", null)
				var id: int = k.get(&"collider_id", 0)
				
				if !(id in _already_processed):
					_already_processed.append(id)
					if l is StaticBumpingBlock:
						if l.has_method(&"got_bumped"):
							l.got_bumped.call_deferred(false)
						elif l.has_method(&"bricks_break"):
							l.bricks_break.call_deferred()
