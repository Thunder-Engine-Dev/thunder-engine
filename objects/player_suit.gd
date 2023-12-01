extends Resource
class_name PlayerSuit

enum Type {
	SMALL,
	SUPER,
	POWERED
}

@export var name: StringName = &"small"
@export var type: Type = Type.SMALL
@export var gets_hurt_to: PlayerSuit
@export_group("Physics", "physics_")
@export var physics_config: PlayerConfig = preload("res://engine/objects/players/prefabs/configs/config_mario_default.tres")
@export var physics_behavior: GDScript = preload("res://engine/objects/players/behaviors/player_physics_behavior.gd")
@export var physics_crouchable: bool = true
@export var physics_shaper: Shaper2D = preload("res://engine/objects/players/prefabs/shapers/shaper_mario_small.tres")
@export var physics_shaper_crouch: Shaper2D = preload("res://engine/objects/players/prefabs/shapers/shaper_mario_small.tres")
@export_group("Animation", "animation_")
@export var animation_sprites: SpriteFrames = preload("res://engine/objects/players/prefabs/animations/mario/animation_mario_small.tres")
@export var animation_behavior: GDScript = preload("res://engine/objects/players/behaviors/player_animation_behavior.gd")
@export_group("Behavior", "behavior_")
@export var behavior_resource: Resource
@export var behavior_script: GDScript
@export_group("Extra", "extra_")
@export var extra_vars: Dictionary
@export var extra_behavior: GDScript
@export_group("Sound", "sound_")
@export var sound_hurt: AudioStream = preload("res://engine/objects/players/prefabs/sounds/pipe.wav")
@export var sound_death: AudioStream = preload("res://engine/objects/players/prefabs/sounds/music-die.ogg")
@export var sound_pitch: float = 1

