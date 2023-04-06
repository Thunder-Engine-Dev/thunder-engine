extends Node2D

@export var detect_by_position: bool = true

@onready var animation_player = $AnimationPlayer
@onready var score_text_marker = $ScoreTextMarker

var triggered: bool = false

func _physics_process(_delta: float) -> void:
	if triggered: return
	
	var player = Thunder._current_player
	if player.is_on_floor() && player.global_position.x > global_position.x:
		Scenes.current_scene.finish(true)
		triggered = true
		animation_player.stop(true)
		Data.values.score += 100
		ScoreText.new("100", score_text_marker)
