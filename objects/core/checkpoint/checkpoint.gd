extends Area2D

const DEFAULT_SWITCH_SOUND := preload("res://engine/objects/core/checkpoint/sounds/switch.wav")

@export var id: int = 0
@export var permanent_checked: bool
@export var sound = DEFAULT_SWITCH_SOUND
## This will override standard universal player voice lines. Leave this array empty if you do not want that.
@export var voice_lines: Array[AudioStream] = []

@onready var text = $Text
@onready var animation_player = $AnimationPlayer
@onready var animation_text_flying: AnimationPlayer = $TextFlying/AnimationTextFlying

@onready var alpha: float = text.modulate.a


func _ready() -> void:
	if SettingsManager.get_tweak("checkpoints", true) == false:
		queue_free()
		return
	
	if Data.values.checkpoint == id:
		Thunder._current_player.global_position = global_position + Vector2.UP.rotated(global_rotation) * 16
		Thunder._current_player.reset_physics_interpolation()
		Thunder._current_camera.teleport()
		text.modulate.a = 1
		animation_player.play(&"checkpoint")


func _physics_process(delta) -> void:
	# Permanent checked
	if permanent_checked && id in Data.values.checked_cps:
		return
	# Activation
	var player: Player = Thunder._current_player
	if player && overlaps_body(player) && Data.values.checkpoint != id:
		Data.values.checkpoint = id
		activate()
		Data.checkpoint_set.emit()
		Data.checkpoint_set_arg.emit(id)
	# Deactivation
	if Data.values.checkpoint != id && animation_player.current_animation == "checkpoint":
		animation_player.play(&"RESET")
		var tween = create_tween()
		tween.tween_property(text, ^"modulate:a", alpha, 0.2)


func activate() -> void:
	if Thunder.autosplitter.can_split_on("checkpoint"):
		Thunder.autosplitter.split()
	var _sfx = CharacterManager.get_sound_replace(sound, DEFAULT_SWITCH_SOUND, "checkpoint_switch", false)
	Audio.play_1d_sound(_sfx, false)
	
	var tween = create_tween()
	tween.tween_property(text, ^"modulate:a", 1.0, 0.2)
	animation_player.play(&"checkpoint")
	if SettingsManager.get_quality() != SettingsManager.QUALITY.MIN:
		animation_text_flying.play(&"triggered")
	
	var _voices
	if !voice_lines.is_empty():
		_voices = voice_lines
	else:
		_voices = CharacterManager.get_voice_line("checkpoint")
	var checkpoint_wait_tweak = CharacterManager.get_global_tweak("checkpoint_sound_delay_sec")
	if !checkpoint_wait_tweak || !checkpoint_wait_tweak is int || !checkpoint_wait_tweak is float:
		checkpoint_wait_tweak = 0.5
	get_tree().create_timer(maxf(0.05, checkpoint_wait_tweak), false, false, true).timeout.connect(func() -> void:
		Audio.play_1d_sound(_voices[randi_range(0, len(_voices) - 1)])
	)
	
	if permanent_checked && !id in Data.values.checked_cps:
		Data.values.checked_cps.append(id)
