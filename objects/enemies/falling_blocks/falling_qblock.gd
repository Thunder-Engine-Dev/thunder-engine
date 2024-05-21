extends GeneralMovementBody2D

signal stun

@export_group("Basic")
@export var trigger_area: Rect2 = Rect2(Vector2(-32, -32), Vector2(64, 480))
@export var stunning_sound: AudioStream = preload("res://engine/objects/bumping_blocks/_sounds/bump.wav")
@export var explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")

var _step: int
var _vel: Vector2
var _origin: Vector2
var _stunspot: Vector2

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body_shape: CollisionShape2D = $Body/CollisionShape2D

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
					return
				# Stops if stunning on the ground
				_step = 2
				_stun()
				_stunspot = global_position
		2:
			set_deferred(&"collision_layer", 0b1110000)
			set_deferred(&"collision_mask", 0b1)
			var shape = collision_shape.shape.duplicate(true)
			shape.size.x = 32
			collision_shape.shape = shape
			body_shape.set_deferred(&"disabled", true)
			$Body/EnemyAttacked.killing_enabled = false
			_step = 3
			$AnimatedSprite2D.flip_v = false
			$AnimatedSprite2D.animation = &"empty"
			

func _stun() -> void:
	stun.emit()
	Audio.play_sound(stunning_sound, self)
	_explosion()


func _explosion() -> void:
	var expl = explosion_effect.instantiate()
	Scenes.current_scene.add_child(expl)
	expl.global_transform = global_transform
	expl.position.y += 16
		
