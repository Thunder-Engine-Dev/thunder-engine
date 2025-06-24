extends Node2D

const SCORING = preload("res://engine/components/hud/sounds/scoring.wav")

@export var move_down_by_px: float = 42
@onready var first_pos: float = position.y
@onready var progress: TextureProgressBar = $Progress

var tw: Tween
var deletion_progress: float
var is_inside: bool

func _ready() -> void:
	modulate.a = 0.0

func _physics_process(delta: float) -> void:
	if !is_inside: return
	
	var is_pressed: bool = Input.is_action_pressed("a_delete")
	progress.visible = deletion_progress > 0.0
	if Input.is_action_just_pressed("a_delete"):
		var _sfx = CharacterManager.get_sound_replace(SCORING, SCORING, "menu_select_short", false)
		Audio.play_1d_sound(_sfx, false)
	if is_pressed:
		deletion_progress = clampf(deletion_progress + delta / 3, 0, 1)
	else:
		deletion_progress = clampf(deletion_progress - delta, 0, 1)
	if progress.visible:
		progress.value = deletion_progress
	if deletion_progress == 1.0:
		deletion_progress = 0.0

func _on_pipe_save_player_enter() -> void:
	if tw: tw.kill()
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tw.tween_property(self, ^"modulate:a", 1.0, 0.1)
	tw.tween_property(self, ^"position:y", first_pos + move_down_by_px, 0.3)
	is_inside = true


func _on_pipe_save_player_exit() -> void:
	if tw: tw.kill()
	if !is_inside_tree(): return
	deletion_progress = 0.0
	progress.visible = false
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tw.tween_property(self, ^"modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tw.tween_property(self, ^"position:y", first_pos, 0.3)
	is_inside = false
