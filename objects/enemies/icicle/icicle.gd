extends GeneralMovementBody2D

signal stun

const DEBRIS_EFFECT = preload("res://engine/objects/effects/brick_debris/brick_debris.tscn")

@export_group("Basic")
@export var trigger_area: Rect2 = Rect2(Vector2(-80, -32), Vector2(160, 480))
@export var stunning_sound: AudioStream = preload("res://engine/objects/projectiles/sounds/stun.wav")
@export var explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")

var _step: int
var _vel: Vector2
var _origin: Vector2
var _stunspot: Vector2

@onready var left_explosion: Marker2D = $LeftExplosion
@onready var right_explosion: Marker2D = $RightExplosion


func _physics_process(delta: float) -> void:
	match _step:
		# Waiting
		0:
			var player: Player = Thunder._current_player
			if !player: return
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
				# Stops if stunning on the ground
				_step = 2
				_stun()
				_stunspot = global_position
		2: queue_free()

func _stun() -> void:
	stun.emit()
	var _sfx = CharacterManager.get_sound_replace(stunning_sound, stunning_sound, "stun", false)
	Audio.play_sound(_sfx, self)
	_explosion()


func _explosion() -> void:
	NodeCreator.prepare_2d(explosion_effect, self) \
		.bind_global_transform(left_explosion.position).create_2d()
	NodeCreator.prepare_2d(explosion_effect, self) \
		.bind_global_transform(right_explosion.position).create_2d()
	var speeds = [Vector2(2, -6), Vector2(4, -7), Vector2(-2, -6), Vector2(-4, -7)]
	for i in speeds:
		NodeCreator.prepare_2d(DEBRIS_EFFECT, self) \
			.bind_global_transform(right_explosion.position).create_2d(true).call_method(func(eff: Node2D):
				eff.texture = preload("./textures/icicle_debris.png")
				eff.velocity = i
		)
