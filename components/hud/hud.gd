extends CanvasLayer

@onready var timer = $Timer
@onready var time_text = $Control/Time
@onready var gameover = $Control/GameOver

@export var scoring_sound = preload("res://engine/components/hud/sounds/scoring.wav")

signal time_countdown_finished


func _ready() -> void:
	Thunder._current_hud = self
	
	timer.timeout.connect(func():
		if Data.values.time < 0: return
		
		Data.values.time -= 1
		
		if Data.values.time == 100:
			timer_hurry()
		elif Data.values.time == 0:
			Thunder._current_player.kill()
	)


func game_over() -> void:
	gameover.show()
	
	get_tree().create_timer(5, false).timeout.connect(Scenes.reload_current_scene)


func timer_hurry() -> void:
	Audio.play_1d_sound(preload("res://engine/components/hud/sounds/timeout.wav"))
	var tw = get_tree().create_tween().set_loops(8)
	tw.tween_property(time_text, "scale:y", 0.5, 0.125)
	tw.tween_property(time_text, "scale:y", 1, 0.125)


func time_countdown() -> void:
	if Data.values.time % 11 == 0: Audio.play_1d_sound(scoring_sound)
	Data.values.time -= 1
	Data.values.score += 10
	if Data.values.time > 0:
		await get_tree().create_timer(0.005).timeout
		time_countdown()
	else:
		time_countdown_finished.emit()
