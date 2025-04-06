extends BowserAttack

@export var projectile_inst: InstanceNode2D = preload("./prefabs/flame.tres")
@export var flame_sound: AudioStream = preload("res://engine/objects/bosses/bowser/sounds/bowser_flame.wav")
@export var flame_delay: float = 0.88
@export var flame_speed_x: float = 200
## The attack will be executed this many times every cycle
@export_range(0.0, 20.0, 1.0) var execute_times_per_attack: int = 1
## Insert number values to the array for multiple flames, numbers being offsets by Y, multiplied by 32
@export var multiple_flames: Array = []
@export_group("Animations")
## Animation name string for preparing to fire
@export var animation_pre: String = "flame_pre"
## Animation name string for firing
@export var animation_after: String = "flame_on"

@onready var pos_flame: Marker2D = $"../PosFlame"
@onready var pos_flame_x: float = pos_flame.position.x


func start_attack() -> void:
	super()
	bowser.sprite.play(animation_pre)
	var tw = create_tween()
	tw.tween_interval(flame_delay)
	tw.tween_callback(middle_attack)


func middle_attack() -> void:
	super()
	if !projectile_inst: return
	Audio.play_sound(flame_sound, bowser, false)
	pos_flame.position.x = pos_flame_x * bowser.facing
	for i in max(1, len(multiple_flames)):
		for _j in execute_times_per_attack:
			NodeCreator.prepare_ins_2d(projectile_inst, bowser).create_2d().call_method(
				func(flm: Node2D) -> void:
					var offset = randi_range(0, 3) if len(multiple_flames) == 0 else multiple_flames[i]
					flm.to_pos_y = bowser.pos_y_on_floor + 16 - 32 * offset
					flm.global_position = pos_flame.global_position
					if flm is Projectile:
						flm.belongs_to = Data.PROJECTILE_BELONGS.ENEMY
						flm.speed.x = flame_speed_x
						flm.speed *= bowser.facing
			)
	end_attack()


func end_attack() -> void:
	super()
	bowser.sprite.play(animation_after)
