extends CanvasLayer

@onready var timer = $Timer
@onready var time_text = $Control/Time
@onready var time_counter: Label = $Control/TimeCounter
@onready var gameover = $Control/GameOver

@export var scoring_sound = preload("res://engine/components/hud/sounds/scoring.wav")

signal time_countdown_finished
signal game_over_finished


func _ready() -> void:
	Thunder._current_hud = self
	
	timer.timeout.connect(func() -> void:
		if !Thunder._current_player: return
		if Data.values.time < 0: return
		
		Data.values.time -= 1
		
		if Data.values.time == 100:
			timer_hurry()
		elif Data.values.time == 0:
			Thunder._current_player.die()
	)
	
	await get_tree().physics_frame
	if Data.values.time < 0:
		time_text.visible = false
		time_counter.visible = false


func game_over() -> void:
	gameover.show()
	
	get_tree().create_timer(6, false).timeout.connect(emit_signal.bind("game_over_finished"))


func timer_hurry() -> void:
	Audio.play_1d_sound(preload("res://engine/components/hud/sounds/timeout.wav"), false, { "bus": "1D Sound" })
	var tw = get_tree().create_tween().set_loops(8)
	tw.tween_property(time_text, "scale:y", 0.5, 0.125)
	tw.tween_property(time_text, "scale:y", 1, 0.125)


func time_countdown(_first_time: bool = true) -> void:
	if _first_time: _time_countdown_sound_loop()
	
	if Data.values.time > 6:
		Data.values.time -= 3
		Data.values.score += 30
	
	if Data.values.time > 0:
		Data.values.time -= 1
		Data.values.score += 10
		await get_tree().create_timer(0.01, false, true).timeout
		time_countdown(false)
	else:
		time_countdown_finished.emit()

func _time_countdown_sound_loop() -> void:
	if Data.values.time > 0:
		Audio.play_1d_sound(scoring_sound, false, { "bus": "1D Sound" })
		await get_tree().create_timer(0.09, false, false, true).timeout
		_time_countdown_sound_loop()
