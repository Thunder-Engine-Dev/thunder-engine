extends Area2D

@export var id: int = 0
@export var sound = preload("res://engine/objects/core/checkpoint/sounds/switch.wav")
@export var voice_lines: Array[AudioStream] = [
	preload("res://engine/objects/core/checkpoint/sounds/voice1.ogg"),
	preload("res://engine/objects/core/checkpoint/sounds/voice2.ogg"),
	preload("res://engine/objects/core/checkpoint/sounds/voice3.ogg")
]

@onready var text = $Text
@onready var animation_player = $AnimationPlayer


func _ready() -> void:
	if Data.values.checkpoint == id:
		Thunder._current_player.global_position = global_position
		$Text.modulate.a = 1
		animation_player.play("checkpoint")


func _physics_process(delta) -> void:
	if overlaps_body(Thunder._current_player) && Data.values.checkpoint != id:
		Data.values.checkpoint = id
		activate()


func activate() -> void:
	Audio.play_1d_sound(sound)
	
	var tween = create_tween()
	tween.tween_property($Text, "modulate:a", 1.0, 0.2)
	animation_player.play("checkpoint")
	
	Audio.play_1d_sound(voice_lines[randi_range(0, len(voice_lines) - 1)])
