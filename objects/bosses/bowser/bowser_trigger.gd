@tool
extends Path2D

@export_category("Bowser's Trigger")
@export_group("Trigger", "trigger_")
@export var trigger_area: Rect2 = Rect2(0, 0, 32, 480)
@export var trigger_bowser: Node2D
@export_group("Camera", "camera_")
@export var camera_speed: float = 50
@export_group("Music")
@export var boss_music: AudioStream = preload("./music/music_bowser_battle.mp3")
@export var boss_music_fading: bool = true

var triggered: bool
var triggered_bowser: bool

@onready var route_follower: PathFollow2D = $RouteFollower
@onready var boss_music_player: AudioStreamPlayer = $BossMusicPlayer


func _draw() -> void:
	if !Engine.is_editor_hint(): return
	draw_set_transform(Vector2.ZERO, -global_rotation, Vector2.ONE/global_scale)
	draw_rect(trigger_area, Color.SLATE_BLUE, false, 4)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		if curve:
			trigger_area.position = curve.get_point_position(0) - trigger_area.size / 2
		return
	
	var player: Player = Thunder._current_player
	if !player: return
	
	if !triggered:
		if trigger_area.has_point(player.global_position):
			var cam: Camera2D = Thunder._current_camera
			if cam: 
				cam.reparent(route_follower)
				cam.par = cam.get_parent()
				cam.force_update_transform()
				cam.force_update_scroll()
			if boss_music:
				boss_music_player.stream
				Audio.stop_all_musics(boss_music_fading)
				if boss_music_fading:
					var tween: Tween = create_tween()
					tween.tween_interval(1.5)
					tween.tween_callback(
						func() -> void:
							boss_music_player.stream = boss_music
							boss_music_player.play()
							if boss_music_fading:
								boss_music_player.volume_db = -40
								Audio.fade_music_1d_player(boss_music_player, 0, 1.5)
					)
			triggered = true
	else:
		if route_follower.progress_ratio < 1.0: 
			route_follower.progress += camera_speed * delta
		var view: Rect2 = Rect2(get_viewport_transform().affine_inverse().get_origin(), get_viewport_rect().size)
		if !triggered_bowser && trigger_bowser && trigger_bowser.is_in_group(&"#bowser") && view.has_point(trigger_bowser.global_position):
			triggered_bowser = true
			trigger_bowser.trigger = self
			trigger_bowser.activate()


func stop_music(fade: bool = true) -> void:
	if fade:
		boss_music_player.stop()
	else:
		Audio.fade_music_1d_player(boss_music_player, -40, 1.5, Tween.TRANS_LINEAR, true)
