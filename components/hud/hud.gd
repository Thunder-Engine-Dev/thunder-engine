extends CanvasLayer

const DEFAULT_HURRY = preload("res://engine/components/hud/sounds/timeout.wav")

@onready var timer = $Timer
@onready var time_text = $Control/Time
@onready var time_counter: Label = $Control/TimeCounter

@onready var gameover = $Control/GameOver
@onready var mario_score: Label = $Control/MarioScore
@onready var coins: Label = $Control/Control/Coins

var game_over_timer: SceneTreeTimer

@export var scoring_sound = preload("res://engine/components/hud/sounds/scoring.wav")
@export var timer_hurry_sound = DEFAULT_HURRY

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
			time_counter.text = "0"
			Thunder._current_player.die()
	)
	Console.executed.connect(_on_console_executed)
	
	await get_tree().physics_frame
	if Data.values.time < 0:
		time_text.visible = false
		time_counter.visible = false


func game_over() -> void:
	gameover.show()
	
	game_over_timer = get_tree().create_timer(6, false)
	Thunder._connect(game_over_timer.timeout, emit_signal.bind("game_over_finished"), CONNECT_ONE_SHOT)
	
	if Data.technical_values.remaining_continues == 0 && "suspended" in ProfileManager.profiles:
		if ProfileManager.profiles.suspended.data.get("saved_profile") == ProfileManager.current_profile.name:
			ProfileManager.delete_profile("suspended")


func _input(event: InputEvent) -> void:
	if !game_over_timer: return
	if game_over_timer.time_left == 0:
		game_over_timer = null
		return
	if event.is_action_pressed(&"ui_accept"):
		game_over_timer = null
		game_over_finished.emit()


func timer_hurry() -> void:
	var _sfx = CharacterManager.get_sound_replace(timer_hurry_sound, DEFAULT_HURRY, "hud_timeout", false)
	Audio.play_1d_sound(_sfx, false, { "bus": "1D Sound" })
	var tw = get_tree().create_tween().set_loops(8)
	tw.tween_property(time_text, "scale:y", 0.5, 0.125)
	tw.tween_property(time_text, "scale:y", 1, 0.125)


func time_countdown(_first_time: bool = true) -> void:
	if _first_time: _time_countdown_sound_loop()
	
	if Data.values.time > 6:
		Data.values.time -= 3
		Data.add_score(30)
	
	if Data.values.time > 0:
		Data.values.time -= 1
		Data.add_score(10)
		await get_tree().create_timer(0.01, false, true).timeout
		time_countdown(false)
	else:
		time_countdown_finished.emit()

func _time_countdown_sound_loop() -> void:
	if Data.values.time > 0:
		Audio.play_1d_sound(scoring_sound, false, { "bus": "1D Sound" })
		await get_tree().create_timer(0.09, false, false, true).timeout
		_time_countdown_sound_loop()


func pulse_label(node: CanvasItem) -> void:
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "modulate:b", 0.2, 0.2).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:b", 1.0, 0.2).set_ease(Tween.EASE_IN)
	tw.tween_property(node, "modulate:b", 0.2, 0.2).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:b", 1.0, 0.2).set_ease(Tween.EASE_IN)


func _on_console_executed(cmd: String, args) -> void:
	if cmd.to_lower() == "hud":
		visible = !visible
