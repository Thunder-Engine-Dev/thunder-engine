@tool
extends GravityBody2D

signal stun

@export_category("Thwomp")
@export_group("Basic")
## If enabled in the editor, draws [member trigger_area] (local space) as a semi-transparent overlay.
@export var draw_trigger_area: bool = false:
	set(v):
		draw_trigger_area = v
		if Engine.is_editor_hint():
			set_process(v)
			queue_redraw()
@export var trigger_area: Rect2 = Rect2(Vector2(-100, -240), Vector2(200, 720)):
	set(v):
		trigger_area = v
		if Engine.is_editor_hint():
			queue_redraw()
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
@onready var timer_destroy: Timer = $Destroy
@onready var left_explosion: RayCast2D = $LeftExplosion
@onready var right_explosion: RayCast2D = $RightExplosion
@onready var collision_shape_2d = $CollisionShape2D


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		set_process(draw_trigger_area)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() && draw_trigger_area:
		queue_redraw()


func _draw() -> void:
	if !Engine.is_editor_hint() || !draw_trigger_area:
		return
	var fill := Color(0.28, 0.82, 1.0, 0.2)
	var outline := Color(0.35, 0.75, 1.0, 0.95)
	draw_rect(trigger_area, fill, true)
	draw_rect(trigger_area, outline, false, 2.0)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
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
	timer_destroy.timeout.connect(queue_free)
	sprite.animation_finished.connect(sprite.play.bind(&"default"))


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	match _step:
		# Waiting
		0:
			collision = false
			collision_shape_2d.disabled = true
			
			var player: Player = Thunder._current_player
			if !player: return
			var ppos: Vector2 = global_transform.affine_inverse() * player.global_position
			if trigger_area.has_point(ppos):
				_origin = global_position
				_step = 1
				timer_destroy.start()
		# Stunning
		1:
			collision = true
			collision_shape_2d.disabled = false
			
			_vel = velocity.normalized()
			motion_process(delta)
			var ray_cast_target = Vector2(0, 4) + (speed * delta * 2).rotated(-global_rotation)
			left_explosion.target_position = ray_cast_target
			right_explosion.target_position = ray_cast_target
			
			if is_on_floor():
				# Breaks Brick
				var bricks: bool
				for i in get_slide_collision_count():
					var collider: Node = get_slide_collision(i).get_collider()
					if collider is StaticBumpingBlock && collider.has_method(&"got_bumped"):
						collider.got_bumped(false)
						if collider.has_method(&"bricks_break") && !collider.result:
							bricks = true
				# Non-stop for the thwomp who broke the bricks
				if bricks:
					_explosion()
					timer_destroy.start()
					return
				# Stops if stunning on the ground
				_stun()
				return
			else:
				var col: bool = false
				var bricks: bool = true
				if left_explosion.is_colliding():
					var collider = left_explosion.get_collider()
					if is_instance_valid(collider) && collider.has_method(&"got_bumped"):
						collider.got_bumped(false)
						if !collider.has_method(&"bricks_break"):
							bricks = false
						col = true
				if right_explosion.is_colliding():
					var collider2 = right_explosion.get_collider()
					if is_instance_valid(collider2) && collider2.has_method(&"got_bumped"):
						collider2.got_bumped(false)
						if !collider2.has_method(&"bricks_break"):
							bricks = false
						col = true
				if col:
					if bricks:
						motion_process(1)
						_explosion()
						timer_destroy.start()
						return
					_step = 2
					_stun.call_deferred()
		# Rising
		3:
			collision = false
			collision_shape_2d.disabled = true
			
			#velocity = -_vel * rising_speed
			velocity = global_position.direction_to(_origin) * rising_speed
			do_movement(delta)
			if (_origin - global_position).dot(_origin - _stunspot) <= 0 && global_position.distance_squared_to(_origin) <= rising_speed * delta:
				velocity = Vector2.ZERO
				speed = velocity
				global_position = _origin
				_stunspot = Vector2.ZERO
				_vel = Vector2.ZERO
				_step = 0


func _stun() -> void:
	_step = 2
	stun.emit()
	timer_destroy.stop()
	var _sfx = CharacterManager.get_sound_replace(stunning_sound, stunning_sound, "stun", false)
	Audio.play_sound(_sfx, self)
	motion_process(1)
	_explosion()
	if Thunder._current_camera.has_method(&"shock"):
		Thunder._current_camera.shock(0.2, Vector2.ONE * 4)
	_stunspot = global_position
	timer_waiting.start(waiting_time)


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
