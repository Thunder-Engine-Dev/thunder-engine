@tool
extends Path2D

@export_category("Bowser's Trigger")
@export_group("Trigger", "trigger_")
@export var trigger_area: Rect2 = Rect2(0, 0, 32, 480)
@export var trigger_bowser: Node2D
@export_group("Camera", "camera_")
@export var camera_speed: float = 50
@export_group("Music")
@export var boss_music: Resource = preload("./music/music_bowser_battle.mp3")
@export var boss_music_fading: bool = true

var _cam_parent: Node

var drawn_rect: Rect2
var triggered: bool
var triggered_bowser: bool

@onready var route_follower: PathFollow2D = $RouteFollower


func _draw() -> void:
	if !Engine.is_editor_hint(): return
	draw_set_transform(Vector2.ZERO, -global_rotation, Vector2.ONE/global_scale)
	draw_rect(drawn_rect, Color.SLATE_BLUE, false, 4)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		if curve:
			drawn_rect.position = global_position + curve.get_point_position(0) - trigger_area.size / 2
			drawn_rect.size = trigger_area.size
		return
	
	var player: Player = Thunder._current_player
	if !player: return
	
	if !triggered:
		if !curve: return
		if !curve.point_count: return
		var actual_area: Rect2 = Rect2(global_position + curve.get_point_position(0) + trigger_area.position - trigger_area.size / 2, trigger_area.size)
		if actual_area.has_point(player.global_position):
			var cam: Camera2D = Thunder._current_camera
			if cam: 
				_cam_parent = cam.get_parent()
				cam.reparent(route_follower)
				cam.par = cam.get_parent()
				cam.force_update_transform()
				cam.force_update_scroll()
			if boss_music:
				Audio.stop_all_musics(boss_music_fading)
				Audio.play_music(boss_music, 32, {} if !boss_music_fading else {
					volume = -40,
					fade_duration = 1.5,
					fade_to = 0
				})
			triggered = true
	else:
		if route_follower.progress_ratio < 1.0: 
			route_follower.progress += camera_speed * delta
		if player.completed:
			var cam: Camera2D = Thunder._current_camera
			if cam && _cam_parent:
				cam.stop_blocking_edges = true
		var view: Rect2 = Rect2(get_viewport_transform().affine_inverse().get_origin(), get_viewport_rect().size)
		if !triggered_bowser && trigger_bowser && trigger_bowser.is_in_group(&"#bowser") && view.has_point(trigger_bowser.global_position):
			triggered_bowser = true
			trigger_bowser.trigger = self
			trigger_bowser.activate()


func stop_music(fade: bool = true) -> void:
	Audio.stop_music_channel(32, true)
