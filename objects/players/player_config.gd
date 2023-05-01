extends Resource
class_name PlayerConfig

@export_subgroup("Walk")
@export var walk_initial_speed: float = 50
@export var walk_acceleration: float = 312.5
@export var walk_deceleration: float = 312.5
@export var walk_turning_acce: float = 1250
@export var walk_max_walking_speed: float = 175
@export var walk_max_running_speed: float = 350
@export_group("Underwater Walk")
@export var underwater_walk_max_walking_speed: float = 175
@export_group("Jump")
@export var jump_speed: float = 700
@export var jump_buff_static: float = 1000
@export var jump_buff_dynamic: float = 1250
@export var jump_stomp_multiplicator: float = 1.0
@export_group("Swim")
@export var swim_speed: float = 150
@export var swim_out_speed: float = 450
@export var swim_max_speed: float = 150
@export_group("Sound", "sound_")
@export var sound_jump: AudioStream = preload("res://engine/objects/players/prefabs/sounds/jump.wav")
@export var sound_swim: AudioStream = preload("res://engine/objects/players/prefabs/sounds/swim.wav")
