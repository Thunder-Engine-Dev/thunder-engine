extends Resource
class_name PlayerConfig

@export_subgroup("Walk", "walk_")
@export var walk_initial_speed: float = 50
@export var walk_acceleration: float = 312.5
@export var walk_deceleration: float = 312.5
@export var walk_crouch_deceleration: float = 468.75
@export var walk_turning_acce: float = 1250
@export var walk_max_walking_speed: float = 175
@export var walk_max_running_speed: float = 350
@export_group("Underwater Walk", "underwater_walk_")
@export var underwater_walk_max_walking_speed: float = 175
@export var underwater_walk_max_running_speed: float = 175
@export_group("Jump", "jump_")
@export var jump_speed: float = 700
@export var jump_buff_static: float = 1000
@export var jump_buff_dynamic: float = 1250
@export var jump_stomp_multiplicator: float = 1.0
@export var jump_coyote_time_sec: float = 0.05
@export_group("Swim", "swim_")
@export var swim_speed: float = 150
@export var swim_out_speed: float = 450
@export var swim_max_speed: float = 150
@export var swim_max_falling_speed: float = 150
@export var swim_gravity_scale: float = 0.1
@export_group("Climb", "climb_")
@export var climb_speed: float = 150
@export_group("Slide", "slide_")
@export var slide_max_speed: float = 450
@export var slide_acceleration: float = 500
@export var slide_deceleration: float = 500
@export_group("Stuck", "stuck_")
@export var stuck_recovery_speed: float = 60
@export_group("Animation", "animation_")
@export var animation_walking_speed: float = 1.5
@export var animation_max_walking_speed: float = 6
@export var animation_min_walking_speed: float = 1
@export_group("Sound", "sound_")
@export var sound_jump: Array = [preload("res://engine/objects/players/prefabs/sounds/jump.wav")]
@export var sound_swim: Array = [preload("res://engine/objects/players/prefabs/sounds/swim.wav")]
@export var sound_skid: Array = [preload("res://engine/objects/players/prefabs/sounds/skid.wav")]
