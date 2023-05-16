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
@export var status_interval: Array[float] = [1]

var tween_hurt: Tween

var active: bool
var direction: int
var facing: int
var lock_direction: bool
var lock_movement: bool
var current_status: StringName

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var animations: AnimationPlayer = $Animations
@onready var enemy_attacked: Node = $Body/EnemyAttacked
@onready var pos_flame: Marker2D = $PosFlame
@onready var pos_flame_x: float = pos_flame.position.x


func _ready() -> void:
	facing = get_facing(facing)
	direction = facing
	activate()


func _physics_process(delta: float) -> void:
	if !active: return
	# Direction
	if !lock_direction:
		facing = get_facing(facing)
	# Animation
	if facing != 0:
		sprite.flip_h = (facing < 0)
	match animations.current_animation:
		&"idle":
			if !is_on_floor(): animations.play(&"jump")
		&"jump":
			if is_on_floor(): animations.play(&"idle")
	# Pos markers
	pos_flame.position.x = pos_flame_x * facing
	# Physics
	motion_process(delta)


func activate() -> void:
	if active: return
	active = true
	direction = get_facing(facing)
	
	var hud: CanvasLayer = HUD.instantiate()
	hud.bowser = self
	health_changed.connect(hud.life_changed)
	add_sibling.call_deferred(hud)
	
	health = health


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


func die() -> void:
	queue_free()


func get_facing(dir: int) -> int:
	var player: Player = Thunder._current_player
	if !player: return dir
	return Thunder.Math.look_at(global_position, player.global_position, global_transform)
