extends Node2D

@onready var first_pos: float = position.y
@onready var down_pos: float = position.y + 42
@onready var progress: TextureProgressBar = $Progress

var tw: Tween
var deletion_progress: float
var is_inside: bool

func _physics_process(delta: float) -> void:
	if !is_inside: return
	
	var is_pressed: bool = Input.is_action_pressed("a_delete")
	progress.visible = deletion_progress > 0.0
	if Input.is_action_just_pressed("a_delete"):
		Audio.play_1d_sound(preload("res://engine/components/hud/sounds/scoring.wav"))
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
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, ^"position:y", down_pos, 0.3)
	is_inside = true


func _on_pipe_save_player_exit() -> void:
	if tw: tw.kill()
	if !is_inside_tree(): return
	deletion_progress = 0.0
	progress.visible = false
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, ^"position:y", first_pos, 0.3)
	is_inside = false
