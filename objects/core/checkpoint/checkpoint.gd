extends Area2D

@export var id: int = 0
@export var permanent_checked: bool
@export var sound = preload("res://engine/objects/core/checkpoint/sounds/switch.wav")
@export var voice_lines: Array[AudioStream] = [
	preload("res://engine/objects/core/checkpoint/sounds/voice1.ogg"),
	preload("res://engine/objects/core/checkpoint/sounds/voice2.ogg"),
	preload("res://engine/objects/core/checkpoint/sounds/voice3.ogg")
]

@onready var text = $Text
@onready var animation_player = $AnimationPlayer

@onready var alpha: float = text.modulate.a


func _ready() -> void:
	if Data.values.checkpoint == id:
		Thunder._current_player.global_position = global_position + Vector2.UP.rotated(global_rotation) * 16
		text.modulate.a = 1
		animation_player.play("checkpoint")


func _physics_process(delta) -> void:
	# Permanent checked
	if permanent_checked && id in Data.values.checked_cps:
		return
	# Activation
	var player: Player = Thunder._current_player
	if player && overlaps_body(player) && Data.values.checkpoint != id:
		Data.values.checkpoint = id
		activate()
	# Deactivation
	if Data.values.checkpoint != id && animation_player.current_animation == "checkpoint":
		animation_player.play("RESET")
		var tween = create_tween()
		tween.tween_property(text, "modulate:a", alpha, 0.2)


func activate() -> void:
	Audio.play_1d_sound(sound, false)
	
	var tween = create_tween()
	tween.tween_property(text, "modulate:a", 1.0, 0.2)
	animation_player.play("checkpoint")
	
	get_tree().create_timer(0.5, false, true).timeout.connect(func() -> void:
		Audio.play_1d_sound(voice_lines[randi_range(0, len(voice_lines) - 1)])
	)
	
	if permanent_checked && !id in Data.values.checked_cps:
		Data.values.checked_cps.append(id)
