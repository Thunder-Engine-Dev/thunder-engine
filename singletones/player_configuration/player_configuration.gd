extends Resource
class_name PlayerConfiguration

# GFX
@export var state_animations: Dictionary = {}
@export var state_scripts: Dictionary = {}

# SFX
@export var jump_sound: Resource
@export var die_music: Resource

# Physics, values are defaulted to Mario config
@export var jump_speed_stopped: float = 20
@export var jump_speed_moving: float = 25
@export var fall_speed: float = 50
@export var max_fall_speed: float = 550
@export var acceleration_speed: float = 12.5
@export var deceleration_speed: float = 5
@export var initial_acceleration: float = 40
@export var initial_accel_trigger: float = 20
@export var max_walk_speed: float = 175
@export var max_run_speed: float = 350
