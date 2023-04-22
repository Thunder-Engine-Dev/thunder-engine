extends Area2D

@onready var initial_position: float = position.y

@onready var score_text_marker = $"../ScoreTextMarker"
@onready var finish_line = $".."
@onready var animation_player = $"../AnimationPlayer"

const CHECKER_BAR = preload("res://engine/objects/core/finish_line/checker_bar.tscn")

func _physics_process(delta) -> void:
	if overlaps_body(Thunder._current_player) && animation_player.is_playing():
		Scenes.current_scene.finish(true)
		finish_line.triggered = true
		_add_score()
		_create_checker_bar()
		animation_player.stop()
		queue_free()

func _add_score() -> void:
	var calculated_y: float = position.y - initial_position
	var given_score: int
	if calculated_y < 30:
		given_score = 10000
	elif calculated_y < 60:
		given_score = 5000
	elif calculated_y < 100:
		given_score = 2000
	elif calculated_y < 150:
		given_score = 1000
	elif calculated_y < 200:
		given_score = 500
	else:
		given_score = 200
	
	Data.values.score += given_score
	ScoreText.new(str(given_score), score_text_marker)

func _create_checker_bar() -> void:
	NodeCreator.prepare_2d(CHECKER_BAR, Scenes.current_scene).create_2d(false).call_method(func(eff: Node2D):
		eff.global_transform = global_transform
		eff.velocity = Vector2(-3, -6)
		eff.fall_speed = 0.2
		eff.rotation_speed = -16
	)
