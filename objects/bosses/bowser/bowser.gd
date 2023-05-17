extends GravityBody2D

signal health_changed(to: int)

const HUD: PackedScene = preload("res://engine/objects/bosses/bowser/bowser_hud.tscn")

@export_category("Bowser")
@export_group("Health")
@export var health: int = 5:
	set(to):
		health = to
		(func() -> void: health_changed.emit(health)).call_deferred()
@export var hardness: int = 5
@export var invincible_flashing_interval: float = 0.5
@export var invincible_duration: float = 2
@export_subgroup("Sounds")
@export var hurt_sound: AudioStream = preload("res://engine/objects/bosses/bowser/sounds/bowser_hurt.wav")
@export var death_sound: AudioStream = preload("res://engine/objects/bosses/bowser/sounds/bowser_died.wav")
@export var falling_sound: AudioStream = preload("res://engine/objects/bosses/bowser/sounds/bowser_fall.wav")
@export var in_lava_sound: AudioStream = preload("res://engine/objects/bosses/bowser/sounds/bowser_in_lava.wav")
@export_group("Status")
## There are the status you can input: [br]
## [b]flame[/b]: shoot single flame [br]
## [b]multiflames[/b]: shoot multiple flames, see [member multiple_flames_amount] [br]
## [b]hammer[/b]: throw hammers, see [member hammer_amount] and [member hammer_interval] [br]
## [b]burst_fireball[/b]: burst out flameballs, see [member burst_fireball_amount]
@export var status: Array[StringName] = [&"flame"]
@export var status_interval: Array[float] = [3]
@export_subgroup("Projectiles")
@export var flame: InstanceNode2D
@export var multiple_flames_amount: int = 3
@export var hammer: InstanceNode2D
@export var hammer_amount: int = 50
@export var hammer_interval: float = 0.08
@export var burst_fireball: InstanceNode2D
@export var burst_fireball_amount: int = 20
@export_subgroup("Sounds")
@export var flame_sound: AudioStream = preload("res://engine/objects/bosses/bowser/sounds/bowser_flame.wav")
@export var hammer_sound: AudioStream = preload("res://engine/objects/projectiles/sounds/throw.wav")
@export var burst_sound: AudioStream = preload("res://engine/objects/enemies/flameball_launcher/sound/flameball.ogg")

var tween_hurt: Tween
var tween_status: Tween

var active: bool
var direction: int
var facing: int
var lock_direction: bool
var lock_movement: bool

var current_status: StringName
var next_status: Array[StringName]
var status_halt: bool
var pos_y_on_floor: float

var _animation_length: float
var _speed: float
var _walking_pausing_factor: float
var _walking_paused: bool

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var animations: AnimationPlayer = $Animations
@onready var enemy_attacked: Node = $Body/EnemyAttacked
@onready var pos_flame: Marker2D = $PosFlame
@onready var pos_flame_x: float = pos_flame.position.x
@onready var pos_hammer: Marker2D = $PosHammer
@onready var pos_hammer_x: float = pos_hammer.position.x


func _ready() -> void:
	_speed = speed.x
	facing = get_facing(facing)
	direction = facing
	vel_set_x(0)
	activate()


func _physics_process(delta: float) -> void:
	if !active: return
	# Direction
	if !lock_direction:
		facing = get_facing(facing)
	# Animation
	if facing != 0:
		sprite.flip_h = (facing < 0)
	match sprite.animation:
		&"default":
			if !is_on_floor(): animations.play(&"bowser/jump")
		&"jump":
			if is_on_floor(): animations.play(&"bowser/idle")
	# Pos markers
	pos_flame.position.x = pos_flame_x * facing
	pos_hammer.position.x = pos_hammer_x * facing
	# Movement
	if !lock_movement:
		_movement(delta)
	elif speed.x != 0:
		_speed = speed.x
		vel_set_x(0)
	# Attack
	if !tween_status:
		tween_status = create_tween()
		for i in status.size():
			tween_status.tween_interval(status_interval[i])
			tween_status.tween_callback(
				func() -> void:
					attack(status[i])
			)
		tween_status.tween_callback(
			func() -> void:
				status_halt = false
				tween_status.kill()
				tween_status = null
		)
	# Physics
	motion_process(delta)
	if is_on_floor():
		pos_y_on_floor = global_transform.affine_inverse().basis_xform(global_position).y


func activate() -> void:
	if active: return
	active = true
	direction = get_facing(facing)
	speed.x = _speed * direction
	# HUD
	var hud: CanvasLayer = HUD.instantiate()
	hud.bowser = self
	health_changed.connect(hud.life_changed)
	add_sibling.call_deferred(hud)
	# Emit the signal
	health = health


# Bowser's attack
func attack(state: StringName) -> void:
	match state:
		&"flame":
			status_halt = true
			if animations.current_animation == &"bowser/flame": return
			animations.play(&"bowser/flame")
			tween_status.pause()
		&"multiflames":
			status_halt = true
			if animations.current_animation == &"bowser/multiple_flames": return
			animations.play(&"bowser/multiple_flames")
			tween_status.pause()
		&"hammer":
			status_halt = true
			attack_hammer()
			tween_status.pause()


# Bowser's flame
func attack_flame(offset_by_32: int = -1) -> void:
	if !flame: return
	NodeCreator.prepare_ins_2d(flame, self).create_2d().call_method(
		func(flm: Node2D) -> void:
			flm.to_pos_y = pos_y_on_floor + 16 - 32 * (randi_range(0, 4) if offset_by_32 < 0 else offset_by_32)
			flm.global_position = pos_flame.global_position
			if flm is Projectile:
				flm.belongs_to = Data.PROJECTILE_BELONGS.ENEMY
				flm.speed *= facing
	)
	if !tween_status.is_running(): tween_status.play()


# Bowser's multiple flames
func multiple_flames() -> void:
	for i in multiple_flames_amount:
		attack_flame(i)


# Bowser's hammer
func attack_hammer() -> void:
	lock_movement = true
	
	# Animation modification
	if sprite.animation != &"throw": sprite.play(&"throw")
	sprite.speed_scale = 0
	sprite.offset.x = 7 * facing
	
	# Lock the animation player from running
	animations.pause()
	
	# Tween for processing attack
	var tween_hammer: Tween = create_tween()
	tween_hammer.tween_interval(2)
	for i in hammer_amount:
		tween_hammer.tween_callback(
			func() -> void:
				sprite.speed_scale = 1
				if !hammer: return
				
				Audio.play_sound(hammer_sound, self, false)
				NodeCreator.prepare_ins_2d(hammer, self).create_2d().call_method(
					func(hm: Node2D) -> void:
						hm.global_position = pos_hammer.global_position
						if hm is Projectile:
							hm.belongs_to = Data.PROJECTILE_BELONGS.ENEMY
							hm.vel_set(Vector2(randf_range(100, 400) * facing, randf_range(-1000, -600)))
				)
		).set_delay(hammer_interval)
	tween_hammer.tween_callback(
		func() -> void:
			sprite.frame = 0
			sprite.speed_scale = 0
	)
	tween_hammer.tween_interval(1)
	# Tween to end the process and restore data
	tween_hammer.tween_callback(
		func() -> void:
			sprite.offset.x = 0
			sprite.speed_scale = 1
			lock_movement = false
			animations.play(&"bowser/idle")
			tween_status.play()
	)


# Bowser's hurt
func hurt() -> void:
	if tween_hurt: return
	
	if health > 0:
		health -= 1
	else:
		die()
		return
	
	var alpha: float = modulate.a
	var stomp_standard: Vector2 = enemy_attacked.stomping_standard
	
	tween_hurt = create_tween()
	tween_hurt.tween_callback(
		func() -> void:
			enemy_attacked.stomping_standard = Vector2.ZERO
	)
	
	for i in ceili(invincible_duration / invincible_flashing_interval):
		tween_hurt.tween_property(self, "modulate:a", 0, invincible_flashing_interval / 2)
		tween_hurt.tween_property(self, "modulate:a", alpha, invincible_flashing_interval / 2)
	
	tween_hurt.tween_callback(
		func() -> void:
			tween_hurt.kill()
			tween_hurt = null
			modulate.a = alpha
			enemy_attacked.stomping_standard = stomp_standard
	)


# Bowser's death
func die() -> void:
	queue_free()


# Gets the facing of the bowser
func get_facing(dir: int) -> int:
	var player: Player = Thunder._current_player
	if !player: return dir
	return Thunder.Math.look_at(global_position, player.global_position, global_transform)


# Reset the current_animation of Animations node to "bowser/idle"
func reset_animation() -> void:
	animations.play(&"bowser/idle")


# Play a sound via property name
func play_sound(sound_name: StringName) -> void:
	if get(sound_name) is AudioStream: Audio.play_sound(get(sound_name), self)


# Bowser's movement
func _movement(delta: float) -> void:
	# Random pausing
	_walking_pausing_factor += delta
	if _walking_pausing_factor >= 0.12:
		_walking_pausing_factor = 0
		# Pausing
		var chance1: float = randf_range(0, 1)
		if chance1 < 0.1 && !_walking_paused:
			_walking_paused = true
			_speed = abs(speed.x)
			vel_set_x(0)
		# Resuming
		var chance2: float = randf_range(0, 1)
		if chance2 < 0.16 && _walking_paused:
			_walking_paused = false
	
	# Keeps moving
	if !_walking_paused: vel_set_x(_speed * direction)
