extends BowserAttack

@export var projectile_inst: InstanceNode2D = preload("./prefabs/burst.tres")
@export var burst_sound: AudioStream = preload("res://engine/objects/enemies/flameball_launcher/sound/flameball.ogg")
@export var burst_delay: float = 3.0
@export var burst_fire_duration: float = 5.0
@export var burst_interval: float = 0.15
@export var burst_speed_min := Vector2(250, -300)
@export var burst_speed_max := Vector2(700, -100)
@export var burst_attack_offset_from_screen_border: float = 128
@export_group("Animations")
## Animation name string for firing
@export var animation_name: String = "burst"

@onready var pos_flame: Marker2D = $"../PosFlame"
@onready var pos_flame_x: float = pos_flame.position.x
var tween_burst: Tween


func start_attack() -> void:
	super()
	var able_to_attack: bool = false
	while is_inside_tree() && is_instance_valid(bowser) && !able_to_attack:
		var bowser_origin: float = bowser.get_global_transform_with_canvas().get_origin().x
		able_to_attack = (
			bowser_origin > burst_attack_offset_from_screen_border &&
			bowser_origin < bowser.get_viewport_rect().size.x - burst_attack_offset_from_screen_border
		)
		await get_tree().physics_frame
		#print(able_to_attack)
	
	bowser.sprite.play(animation_name)
	bowser.lock_movement = true
	bowser.lock_direction = true
	bowser.sprite.play(&"burst")
	bowser.sprite.speed_scale = 0
	
	var tw = create_tween()
	tw.tween_interval(burst_delay)
	tw.tween_callback(middle_attack)


func middle_attack() -> void:
	super()
	
	bowser.sprite.speed_scale = 1
	bowser.jump_enabled = false
	if !projectile_inst: return
	
	# Tween to end the process and restore data
	get_tree().create_timer(burst_fire_duration, false, true).timeout.connect(end_attack)
	# Tween for processing attack
	tween_burst = create_tween().set_loops()
	tween_burst.tween_callback(func() -> void:
		pos_flame.position.x = pos_flame_x * bowser.facing
		Audio.play_sound(burst_sound, bowser, false)
		NodeCreator.prepare_ins_2d(projectile_inst, bowser).create_2d().call_method(
			func(bf: Node2D) -> void:
				bf.global_position = pos_flame.global_position
				if bf is Projectile:
					bf.belongs_to = Data.PROJECTILE_BELONGS.ENEMY
					bf.vel_set(Vector2(
						randf_range(burst_speed_min.x, burst_speed_max.x) * bowser.facing,
						randf_range(burst_speed_min.y, burst_speed_max.y)
					))
		)
	).set_delay(burst_interval)


func end_attack() -> void:
	super()
	if tween_burst:
		tween_burst.stop()
	bowser.sprite.speed_scale = 1
	bowser.sprite.play("default")
	bowser.lock_movement = false
	bowser.lock_direction = false
	bowser.jump_enabled = true
