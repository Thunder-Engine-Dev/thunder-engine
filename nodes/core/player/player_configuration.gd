extends Resource
class_name PlayerConfiguration

# Controls
@export_group("Controls")
@export var control_left:StringName = &"m_left"
@export var control_right:StringName = &"m_right"
@export var control_up:StringName = &"m_up"
@export var control_down:StringName = &"m_down"
@export var control_jump:StringName = &"m_jump"
@export var control_run:StringName = &"m_run"

# GFX
@export_group("GFX")
@export var state_animations: Dictionary
@export var state_scripts: Dictionary

# SFX
@export_group("SFX")
@export var jump_sound: AudioStream
@export var die_music: Resource

# Physics, values are defaulted to Mario config
@export_group("Physics")
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
