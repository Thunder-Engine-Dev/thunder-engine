extends Node2D

@export_category("Hammer Bro")
@export_group("Physics")
@export var amplitude: Vector2 = Vector2(0, 50)
@export var frequency: float = 100
@export var phase: float
@export var random_phase: bool = true
@export_group("Attack")
@export var attacking_count_unit: float = 0.06
@export var attacking_chance: float = 0.09
@export var attacking_delay: float = 0.6
@export var projectile: InstanceNode2D
@export var sound: AudioStream = preload("res://engine/objects/projectiles/sounds/throw.wav")
@export_group("Animation")
@export var sprite_projectile_animation_transform: Array[Transform2D] = [
	Transform2D(0, Vector2.ZERO),
	Transform2D(0, Vector2.ZERO)
]

var dir: int

var _step_attacking: int

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var sprite_projectile: Node2D = $SpriteProjectile
@onready var timer_attack: Timer = $Attack

@onready var pos: Vector2 = position
@onready var posx: float = global_transform.affine_inverse().basis_xform(global_position).x
@onready var pos_attack: Marker2D = $PosAttack
@onready var pos_attack_x: float = pos_attack.position.x
@onready var vision: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D


func _ready() -> void:
	vision.rect.size = vision.rect.size.max(amplitude * 2)
	vision.rect.position = -(vision.rect.position.max(amplitude))
	if random_phase: phase = Thunder.rng.get_randf_range(-180, 180)


func _physics_process(delta: float) -> void:
	_direction()
	_animation()
	_oval(delta)


func _oval(delta: float) -> void:
	position = Thunder.Math.oval(pos, amplitude, deg_to_rad(phase))
	phase = wrapf(phase + frequency * delta, -180, 180)


# Facing direction, not walking one
func _direction() -> void:
	var player: Player = Thunder._current_player
	if !player: return
	dir = Thunder.Math.look_at(global_position, player.global_position, global_transform)
	sprite.flip_h = dir < 0
	sprite_projectile.flip_h = sprite.flip_h
	pos_attack.position.x = pos_attack_x * dir


func _animation() -> void:
	if _step_attacking > 0:
		sprite.play(&"attack")
		sprite_projectile.visible = true
		
		var trans: Transform2D = sprite_projectile_animation_transform[sprite.frame]
		trans.origin.x *= dir
		sprite_projectile.transform = pos_attack.transform * trans
	else:
		sprite.play(&"default")
		sprite_projectile.visible = false


# Attack
func _on_attack_timeout() -> void:
	match _step_attacking:
		# Detection for attack
		0:
			var chance: float = Thunder.rng.get_randf_range(0, 1)
			if chance < attacking_chance:
				_step_attacking = 1
				timer_attack.start(attacking_delay)
				timer_attack.one_shot = true
		# Attack
		1:
			_step_attacking = 0
			timer_attack.start(attacking_count_unit)
			timer_attack.one_shot = false
			NodeCreator.prepare_ins_2d(projectile, self).call_method(
				func(proj: Node2D) -> void:
					proj.set(&"belongs_to", Data.PROJECTILE_BELONGS.ENEMY)
			).execute_instance_script({bro = self}).create_2d().bind_global_transform(pos_attack.position)
			Audio.play_sound(sound, self, false)
