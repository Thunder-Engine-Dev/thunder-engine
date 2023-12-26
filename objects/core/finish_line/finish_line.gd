extends Node2D

@export var detect_by_position: bool = true

@export_enum("Left: -1", "Right: 1") var direction_to_complete: int = 1
@export var use_strict_detection_area: bool
@export var strict_completion_area_path: NodePath = ^"CompletionArea"
@export var player_walking_speed: float = 125

@onready var animation_player = $AnimationPlayer
@onready var score_text_marker = $ScoreTextMarker

var triggered: bool = false


func _physics_process(_delta: float) -> void:
	if triggered: return
	
	var player = Thunder._current_player
	if !player: return
	
	var completion_area = get_node(strict_completion_area_path)
	var completion1: bool = (
		-20 * direction_to_complete + (
			player.global_position.x - global_position.x
		) * direction_to_complete > 0 && !use_strict_detection_area
	)
	var completion2: bool = completion_area.overlaps_body(player) && use_strict_detection_area
	if player.is_on_floor() && (completion1 || completion2):
		Scenes.current_scene.finish(true, direction_to_complete)
		triggered = true
		animation_player.stop(true)
		Data.values.score += 100
		ScoreText.new("100", score_text_marker)
