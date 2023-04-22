extends GravityBody2D

signal stun

@export_category("Thwomp")
@export_group("Basic")
@export var trigger_area: Rect2 = Rect2(Vector2(-64, -32), Vector2(128, 480))
@export var waiting_time: float = 1
@export var rising_speed: float = 50
@export_group("Effect and Sound")
@export var laughing_sound: AudioStream = preload("res://engine/objects/enemies/thwomp/sounds/laughing.wav")
@export var stunning_sound: AudioStream = preload("res://engine/objects/projectiles/sounds/stun.wav")
@export var explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")

var _step: int
var _vel: Vector2
var _origin: Vector2
var _stunspot: Vector2

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var timer_smile: Timer = $Smile
@onready var timer_blink: Timer = $Blink
@onready var timer_waiting: Timer = $Waiting
@onready var left_explosion: RayCast2D = $LeftExplosion
@onready var right_explosion: RayCast2D = $RightExplosion


func _ready() -> void:
	timer_blink.start(randf_range(1, 6))
	timer_blink.timeout.connect(
		func() -> void:
			if sprite.animation == &"smile":
				return
			timer_blink.start(randf_range(1, 6))
			sprite.play(&"blink")
	)
	timer_smile.timeout.connect(sprite.play.bind(&"default"))
	timer_waiting.timeout.connect(
		func() -> void:
			_step = 3
	)
	sprite.animation_finished.connect(sprite.play.bind(&"default"))


func _physics_process(delta: float) -> void:
	match _step:
		# Waiting
		0:
			var player: Player = Thunder._current_player
			if !player: return
			if player.states.current_state == "dead": return
			var ppos: Vector2 = global_transform.affine_inverse() * player.global_position
			if trigger_area.has_point(ppos):
				_origin = global_position
				_step = 1
		# Stunning
		1:
			_vel = velocity.normalized()
			motion_process(delta)
			if is_on_floor():
				# Breaks Brick
				var bricks: bool
				for i in get_slide_collision_count():
					var j: KinematicCollision2D = get_slide_collision(i)
					if j.get_collider() is StaticBumpingBlock && j.get_collider().has_method(&"bricks_break"):
						j.get_collider().bricks_break.call_deferred()
						bricks = true
				# Non-stop for the thwomp who broke the bricks
				if bricks:
					_explosion()
					return
				# Stops if stunning on the ground
				_step = 2
				_stun()
				_stunspot = global_position
				timer_waiting.start(waiting_time)
		# Rising
		3:
			velocity = -_vel * rising_speed
			do_movement(delta)
			if (_origin - global_position).dot(_origin - _stunspot) <= 0:
				velocity = Vector2.ZERO
				speed = velocity
				global_position = _origin
				_stunspot = Vector2.ZERO
				_vel = Vector2.ZERO
				_step = 0


func _stun() -> void:
	stun.emit()
	Audio.play_sound(stunning_sound, self)
	_explosion()
	if Thunder._current_camera.has_method(&"shock"):
		Thunder._current_camera.shock(0.2, Vector2.ONE * 8)


func _explosion() -> void:
	NodeCreator.prepare_2d(explosion_effect, self).bind_global_transform(left_explosion.position).create_2d().call_method(
		func(eff: Node2D) -> void:
			left_explosion.force_raycast_update()
			if !left_explosion.is_colliding():
				eff.queue_free()
	)
	NodeCreator.prepare_2d(explosion_effect, self).bind_global_transform(right_explosion.position).create_2d().call_method(
		func(eff: Node2D) -> void:
			right_explosion.force_raycast_update()
			if !right_explosion.is_colliding():
				eff.queue_free()
	)


func _on_smile() -> void:
	if sprite.animation == &"smile": return
	Audio.play_sound(laughing_sound, self)
	sprite.play(&"smile")
	timer_smile.start()
