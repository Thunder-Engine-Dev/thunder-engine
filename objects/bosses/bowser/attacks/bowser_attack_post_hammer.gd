extends BowserAttack

## Bowser's hammer attack

@export var wait_time: float = 1.5
@export_group("Movement")
@export var lock_movement: bool = true
@export var lock_direction: bool = false
@export_group("Animations")
## Animation name string for preparing to fire
@export var animation_pre: String = "throw_pre"
@export var sprite_offset_x: float = 7


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
	var tween: Tween = create_tween()
	tween.tween_interval(wait_time)
	# Tween to end the process and restore data
	tween.tween_callback(end_attack)


func end_attack() -> void:
	super()
	bowser.sprite.offset.x = 0
	bowser.sprite.play(&"default")
	bowser.lock_movement = false
	bowser.lock_direction = false
