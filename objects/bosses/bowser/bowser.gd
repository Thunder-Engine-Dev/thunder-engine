extends GravityBody2D

signal health_changed(to: int)

const HUD: PackedScene = preload("./bowser_hud.tscn")
const CORPSE: PackedScene = preload("./corpse/bowser_corpse.tscn")

@export_category("Bowser")
@export_group("Health")
@export var health: int = 5:
	set(to):
		health = to
		(func() -> void: health_changed.emit(health)).call_deferred()
## Projectile health, will remove a point from [member health] when it hits 0
@export var hardness: int = 5
@export var invincible_flashing_interval: float = 0.8
@export var invincible_duration: float = 2
@export var instakill_from_lava: bool = true
@export_subgroup("Sounds")
@export var hurt_sound: AudioStream = preload("res://engine/objects/bosses/bowser/sounds/bowser_hurt.wav")
@export var death_sound: AudioStream = preload("res://engine/objects/bosses/bowser/sounds/bowser_died.wav")
@export var falling_sound: AudioStream = preload("res://engine/objects/bosses/bowser/sounds/bowser_fall.wav")
@export var into_lava_sound: AudioStream = preload("res://engine/objects/bosses/bowser/sounds/bowser_into_lava.wav")
@export_group("Status")
@export var status_interval: Array[float] = [3]
## These are the statuses you can input: [br]
## [b]flame[/b]: shoot single flame [br]
## [b]multiflames[/b]: shoot multiple flames, see [member multiple_flames_amount] [br]
## [b]hammer[/b]: throw hammers, see [member hammer_amount] and [member hammer_interval] [br]
## [b]burst[/b]: burst out flameballs, see [member burst_fireball_amount]
@export var status: Array[StringName] = [&"flame"]
@export_subgroup("Projectiles")
@export var flame: InstanceNode2D
@export var multiple_flames_amount: int = 3
@export var hammer: InstanceNode2D
@export var hammer_amount: int = 20
@export var hammer_interval: float = 0.08
@export var burst_fireball: InstanceNode2D
@export var burst_fireball_amount: int = 30
#@export_subgroup("Sounds")
#@export var flame_sound: AudioStream = preload("res://engine/objects/bosses/bowser/sounds/bowser_flame.wav")
#@export var hammer_sound: AudioStream = preload("res://engine/objects/projectiles/sounds/throw.wav")
#@export var burst_sound: AudioStream = preload("res://engine/objects/enemies/flameball_launcher/sound/flameball.ogg")
@export_group("Jumping")
@export var jumping_interval: float = 0.15
@export var jumping_chance: float = 0.05
@export var jumping_speed: float = 300
@export_group("Level Setting")
@export var finish_on_death: bool = true
@export_enum("Left: -1", "Right: 1") var complete_direction: int = 1
@export_group("HUD")
@export var y_offset: int = 0

var tween_hurt: Tween
var tween_hurt_blinking: Tween
var tween_status: Tween

var active: bool
var direction: int
var facing: int
var lock_direction: bool
var lock_movement: bool
var jump_enabled: bool = true

var trigger: Node2D

var pos_y_on_floor: float

var _speed: float
var _walking_counter: float
var _walking_move_distance: float
var _jump_factor: float

var _bullet_received: int

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var enemy_attacked: Node = $Body/EnemyAttacked
#@onready var pos_flame: Marker2D = $PosFlame
#@onready var pos_flame_x: float = pos_flame.position.x
#@onready var pos_hammer: Marker2D = $PosHammer
#@onready var pos_hammer_x: float = pos_hammer.position.x
@onready var debug_text: Label = $Debug
@onready var debug_text_template: String = debug_text.text

@onready var initial_killing_immune: Dictionary = enemy_attacked.killing_immune.duplicate(true)
@onready var tweaked_stomping: bool = SettingsManager.get_tweak("bowser_stomping", false)
@onready var player: Player = Thunder._current_player

var _attacking: bool
var _tweaked_stomping_vel: float
var hud: CanvasLayer


func _ready() -> void:
	super()
	if instakill_from_lava:
		$Body.add_to_group(&"#lava_body")
	sprite.animation_looped.connect(_on_sprite_animation_looped)
	_speed = speed.x
	facing = get_facing(facing)
	direction = facing
	vel_set_x(0)
	#enemy_attacked.killing_immune = {}
	if tweaked_stomping:
		enemy_attacked.stomping_player_jumping_max = enemy_attacked.stomping_player_jumping_min
	
	# HUD
	hud = HUD.instantiate()
	hud.bowser = self
	hud.y_offset = y_offset
	health_changed.connect(hud.life_changed)
	add_sibling.call_deferred(hud)


func _physics_process(delta: float) -> void:
	# Direction
	if !lock_direction:
		facing = get_facing(facing)
		if sprite.animation == &"throw":
			sprite.offset.x = 7 * facing
			sprite.reset_physics_interpolation()
	
	# Animation
	if facing != 0:
		sprite.flip_h = (facing < 0)
	
	if !active: return
	if is_on_floor() && sprite.animation == &"jump" || !sprite.is_playing():
		sprite.play(&"default")
	if sprite.animation == &"default" && !is_on_floor():
		sprite.play(&"jump")
	
	# Pos markers
	#pos_flame.position.x = pos_flame_x * facing
	#pos_hammer.position.x = pos_hammer_x * facing
	
	# Movement
	if !lock_movement:
		_movement(delta)
	elif speed.x != 0:
		_speed = abs(speed.x)
		vel_set_x(0)
	
	# Jump
	if jump_enabled:
		_jumping(delta)
	
	# Attack
	if !tween_status:
		tween_status = create_tween()
		for i in status.size():
			tween_status.tween_interval(status_interval[i])
			tween_status.tween_callback(attack.bind(status[i]))
		if _attacking:
			tween_status.pause()
		tween_status.finished.connect(func() -> void:
			tween_status = null
		)
	else:
		debug_text.text = debug_text_template % [
			tween_status.get_total_elapsed_time(), tween_status.is_running(), tween_status.get_loops_left()
		]
	
	# Physics
	motion_process(delta)
	if is_on_floor():
		pos_y_on_floor = global_transform.affine_inverse().basis_xform(global_position).y
	
	debug_text.visible = Console.cv.player_stats_shown
	
	# Old bowser stomping (Tweak)
	if !tweaked_stomping || !_tweaked_stomping_vel: return
	if is_instance_valid(player) && !player.is_on_wall():
		player.position.x += _tweaked_stomping_vel * 50 * delta
	_tweaked_stomping_vel = move_toward(_tweaked_stomping_vel, 0.0, 50 * delta)


func activate() -> void:
	if active: return
	active = true
	direction = get_facing(facing)
	speed.x = _speed * direction
	_walking_move_distance = randf_range(0, 64)
	# Emit the signal
	health = health
	#enemy_attacked.killing_immune = initial_killing_immune.duplicate(true)
	player = Thunder._current_player


# Bowser's attack
func attack(state: StringName) -> void:
	var _attack_node: BowserAttack = get_node_or_null("attack_" + state)
	assert(_attack_node && _attack_node is BowserAttack, "Please attach a BowserAttack node named attack_" + state + ".")
	if !_attack_node is BowserAttack:
		return
	
	tween_status.pause()
	_attacking = true
	_attack_node._accept_attack(self)


func _on_sprite_animation_looped() -> void:
	if sprite.animation in [&"jump", &"throw_pre"]:
		sprite.set_frame_and_progress(sprite.sprite_frames.get_frame_count(sprite.animation) - 1, 0.0)
	elif sprite.animation == &"flame_pre_multiple":
		sprite.set_frame_and_progress(sprite.sprite_frames.get_frame_count(sprite.animation) - 3, 0.0)


# Bowser's hurt
func hurt(_external_damage_source: bool = false) -> void:
	if tween_hurt: return
	enemy_attacked.killing_immune = {}
	
	if !_external_damage_source && tweaked_stomping && is_instance_valid(player):
		_tweaked_stomping_vel = 8 * player.direction
	
	_bullet_received = 0
	if health > 0:
		var _sfx = CharacterManager.get_sound_replace(hurt_sound, hurt_sound, "bowser_hurt", false)
		Audio.play_sound(_sfx, self)
		health -= 1
	if health <= 0:
		die()
		return
	
	var stomp_standard: Vector2 = enemy_attacked.stomping_standard
	
	tween_hurt = create_tween()
	tween_hurt.tween_callback(
		func() -> void:
			enemy_attacked.stomping_standard = Vector2.ZERO
	)
	tween_hurt.tween_interval(invincible_duration)
	
	if tween_hurt_blinking:
		tween_hurt_blinking.stop()
	sprite.modulate.a = 1.0
	tween_hurt_blinking = create_tween()
	
	for i in ceili(invincible_duration / invincible_flashing_interval):
		tween_hurt_blinking.tween_property(sprite, "modulate:a", 0.25, invincible_flashing_interval / 2)
		tween_hurt_blinking.tween_property(sprite, "modulate:a", 1.0, invincible_flashing_interval / 2)
	
	tween_hurt.finished.connect(func() -> void:
		tween_hurt.kill()
		tween_hurt = null
		sprite.modulate.a = 1.0
		enemy_attacked.stomping_standard = stomp_standard
		enemy_attacked.killing_immune = initial_killing_immune.duplicate(true)
	, CONNECT_ONE_SHOT)

# Hurt from bullets
func bullet_hurt() -> void:
	if tween_hurt: return
	
	_bullet_received += 1
	if _bullet_received >= hardness:
		_bullet_received = 0
		hurt(true)


# Bowser's death
func die(corpse_intro: bool = true) -> void:
	print("[Game] Boss defeated.")
	var _sfx = CharacterManager.get_sound_replace(death_sound, death_sound, "bowser_be_happy", false)
	Audio.play_sound(_sfx, self)
	tween_hurt_blinking = null
	if health > 0: health = 0
	
	if finish_on_death && trigger.has_method(&"stop_music"):
		if Thunder.autosplitter.can_split_on("boss_defeat"):
			Thunder.autosplitter.split()
		Scenes.current_scene.set_meta(&"boss_got_defeated", true)
		trigger.stop_music()
	
	NodeCreator.prepare_2d(CORPSE, self).bind_global_transform().call_method(
		func(cps: Node2D) -> void:
			if !corpse_intro:
				cps.duration = -1
	).create_2d().call_method(
		func(cps: Node2D) -> void:
			var spr: AnimatedSprite2D = sprite.duplicate()
			cps.add_child(spr)
			spr.modulate.a = 1.0
			spr.speed_scale = 1
			spr.play.call_deferred(&"death")
			cps.add_child.call_deferred(collision_shape.duplicate())
			var _sfx2 = CharacterManager.get_sound_replace(falling_sound, falling_sound, "bowser_fall", false)
			cps.falling_sound = _sfx2
			_sfx2 = CharacterManager.get_sound_replace(into_lava_sound, into_lava_sound, "bowser_lava_love", false)
			cps.into_lava_sound = _sfx2
			cps.direction_to_complete = complete_direction
			cps.finish_on_free = finish_on_death
	)
	queue_free()


# Gets the facing of the bowser
func get_facing(dir: int) -> int:
	if !player: return dir
	return Thunder.Math.look_at(global_position, player.global_position, global_transform)


# Bowser's movement
func _movement(delta: float) -> void:
	# Update the random pausing every second
	if _walking_counter < 1.0:
		_walking_counter += delta
	else:
	# Setting random distance to walk
		_walking_move_distance = randf_range(0, 64)
		_walking_counter = 0.0
	
	if _walking_move_distance > 0.0:
		vel_set_x(_speed * direction)
		_walking_move_distance -= delta * 50
	# Pausing
	else:
		vel_set_x(0)


# Bowser's Jumping
func _jumping(delta: float) -> void:
	if !is_on_floor():
		return
	_jump_factor += delta
	if _jump_factor < jumping_interval:
		return
	
	_jump_factor = 0
	# Jumping
	var chance: float = randf_range(0, 1)
	if chance < jumping_chance: jump(jumping_speed)
