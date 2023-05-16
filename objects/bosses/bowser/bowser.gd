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
@export var status: Array[StringName] = [&"flame"]
@export var status_interval: Array[float] = [3]
@export_subgroup("Projectiles")
@export var flame: InstanceNode2D
@export var hammer: InstanceNode2D
@export var burst_fireball: InstanceNode2D
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

var _speed: float
var _walking_pausing_factor: float
var _walking_paused: bool

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var animations: AnimationPlayer = $Animations
@onready var enemy_attacked: Node = $Body/EnemyAttacked
@onready var pos_flame: Marker2D = $PosFlame
@onready var pos_flame_x: float = pos_flame.position.x


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
	# Movement
	_movement(delta)
	# Attack
	if !tween_status:
		tween_status = create_tween()
		for i in status.size():
			tween_status.tween_interval(status_interval[i])
			tween_status.tween_callback(
				func() -> void:
					attack(status[i])
			)
			tween_status.tween_interval(0.0 if !status_halt else animations.current_animation_length)
			tween_status.tween_callback(
				func() -> void:
					status_halt = false
					tween_status.kill()
					tween_status = null
			)
	# Physics
	motion_process(delta)


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


func reset_animation() -> void:
	animations.play(&"bowser/idle")


func play_sound(sound_name: StringName) -> void:
	if get(sound_name) is AudioStream: Audio.play_sound(get(sound_name), self)


func die() -> void:
	queue_free()


func get_facing(dir: int) -> int:
	var player: Player = Thunder._current_player
	if !player: return dir
	return Thunder.Math.look_at(global_position, player.global_position, global_transform)


# Bowser's movement
func _movement(delta: float) -> void:
	if lock_movement: return
	
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
