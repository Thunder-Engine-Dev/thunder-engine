extends GravityBody2D

var movement: bool

@onready var game_over_music: AudioStream = load(ProjectSettings.get_setting("application/thunder_settings/player/gameover_music"))


func _ready() -> void:
	await get_tree().create_timer(0.5, false, true).timeout
	movement = true
	vel_set_y(-650)
	await get_tree().create_timer(4, false, true).timeout
	# After death
	if Data.values.lives == 0:
		if is_instance_valid(Thunder._current_hud):
			Thunder._current_hud.game_over()
			Audio.play_music(game_over_music, 1)
		return
	Thunder._current_player_state = null
	Scenes.reload_current_scene()
	Data.values.lives -= 1


func _physics_process(delta: float) -> void:
	if !movement:
		return
	motion_process(delta)
