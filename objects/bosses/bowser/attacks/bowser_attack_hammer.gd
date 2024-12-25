extends BowserAttack

## Bowser's hammer attack

@export var projectile_inst: InstanceNode2D = preload("./prefabs/hammer.tres")
@export var throw_sound: AudioStream = preload("res://engine/objects/projectiles/sounds/throw.wav")
@export var pre_delay: float = 2.0
@export var hammer_amount: int = 15
@export var hammer_interval: float = 0.12
@export var hammer_speed_min := Vector2(70, -800)
@export var hammer_speed_max := Vector2(400, -250)
@export_group("Movement")
@export var lock_movement: bool = true
@export var lock_direction: bool = false
@export_group("Animations")
## Animation name string for preparing to fire
@export var animation_pre: String = "throw_pre"
## Animation name string for firing
@export var animation_after: String = "throw"
@export var sprite_offset_x: float = 7

@onready var pos_hammer: Marker2D = $"../PosHammer"
@onready var pos_hammer_x: float = pos_hammer.position.x


func _physics_process(delta: float) -> void:
	if bowser && bowser.sprite.animation in [animation_after, animation_pre]:
		pos_hammer.position.x = pos_hammer_x * bowser.facing
		bowser.sprite.offset.x = sprite_offset_x * bowser.facing
		bowser.sprite.reset_physics_interpolation()


func start_attack() -> void:
	super()
	bowser.lock_movement = lock_movement
	bowser.lock_direction = lock_direction
	
	# Animation modification
	bowser.sprite.play(animation_pre)
	bowser.sprite.offset.x = sprite_offset_x * bowser.facing
	bowser.sprite.reset_physics_interpolation()
	middle_attack()


func middle_attack() -> void:
	super()
	# Tween for processing attack
	var tween_hammer: Tween = create_tween()
	tween_hammer.tween_interval(pre_delay)
	for i in hammer_amount:
		tween_hammer.tween_callback(
			func() -> void:
				if !projectile_inst: return
				if bowser.sprite.animation != animation_after:
					bowser.sprite.play(animation_after)
				
				Audio.play_sound(throw_sound, bowser, false)
				NodeCreator.prepare_ins_2d(projectile_inst, bowser).create_2d().call_method(
					func(hm: Node2D) -> void:
						hm.global_position = pos_hammer.global_position
						if hm is Projectile:
							hm.belongs_to = Data.PROJECTILE_BELONGS.ENEMY
							hm.vel_set(
								Vector2(
									randf_range(hammer_speed_min.x, hammer_speed_max.x) * bowser.facing,
									randf_range(hammer_speed_min.y, hammer_speed_max.y)
								)
							)
				)
		).set_delay(hammer_interval)
	tween_hammer.tween_callback(
		func() -> void:
			bowser.sprite.play(animation_pre)
	)
	# Tween to end the process and restore data
	tween_hammer.tween_callback(end_attack)


func end_attack() -> void:
	super()
	bowser.sprite.offset.x = 0
	bowser.sprite.play(&"default")
	bowser.lock_movement = false
	bowser.lock_direction = false
