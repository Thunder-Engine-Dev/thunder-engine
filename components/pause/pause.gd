extends Control

var opened: bool = false
var open_blocked: bool = false
var _no_unpause: bool = false
var _prev_mouse_mode: Input.MouseMode

const open_sound = preload("./sounds/pause_open.wav")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var v_box_container: MenuItemsController = $VBoxContainer
@onready var options: MenuItemsController = $"../Settings/SubViewportContainer/SubViewport/Options"
@onready var controls_scene: Control = $"../Controls"

signal paused
signal unpaused

var _music_volume_tween: Tween

func _ready() -> void:
	Scenes.custom_scenes.pause = self
	Scenes.scene_shortcut_pressed.connect(reset_state)
	animation_player.play(&"init")
	Scenes.scene_changed.connect(_on_scene_changed)


func _unhandled_input(event: InputEvent) -> void:
	if &"game_over" in Scenes.custom_scenes && Scenes.custom_scenes.game_over.opened: return
	if event.is_action_pressed(&"pause_toggle") && (
		Scenes.current_scene is Stage2D ||
		Scenes.current_scene is Map2D
	) && !(opened && event.is_action_pressed("ui_cancel")) && !Scenes.current_scene.get(&"disable_pause_menu"):
		toggle()


func toggle(no_resume: bool = false, no_sound_effect: bool = false) -> void:
	if !v_box_container.focused && opened: return
	if !is_inside_tree(): return

	if !opened && is_instance_valid(TransitionManager.current_transition):
		return

	if open_blocked: return

	opened = !opened
	if opened:
		paused.emit()
	else:
		unpaused.emit()

	$'..'.offset = Vector2.ZERO

	if is_instance_valid(_music_volume_tween):
		_music_volume_tween.kill()
	var target_volume: float = -20.0 if opened else 0.0
	_music_volume_tween = Audio.create_tween().set_ease(Tween.EASE_IN).set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_music_volume_tween.tween_property(Audio, "_target_music_bus_volume_db", target_volume, 0.3)

	if opened:
		v_box_container.move_selector(0, true)
		animation_player.play("open")
		if !no_sound_effect:
			var _sfx = CharacterManager.get_sound_replace(open_sound, open_sound, "hud_pause_open", false)
			Audio.play_1d_sound(_sfx, true, { "ignore_pause": true, "bus": "1D Sound" })
		_prev_mouse_mode = SettingsManager.mouse_mode
		SettingsManager.show_mouse()
	else:
		animation_player.play_backwards("open")
		if _prev_mouse_mode != Input.MOUSE_MODE_VISIBLE:
			SettingsManager.hide_mouse()
	
	get_tree().paused = opened if !_no_unpause else true
	v_box_container.focused = false

	for i in 2:
		await get_tree().physics_frame

	v_box_container.focused = opened
	options.focused = false
	controls_scene.unfocus_all_menus()


func reset_state() -> void:
	if is_instance_valid(_music_volume_tween):
		_music_volume_tween.kill()
		_music_volume_tween = null
	Audio._target_music_bus_volume_db = 0.0

	if opened:
		unpaused.emit()
		if _prev_mouse_mode != Input.MOUSE_MODE_VISIBLE:
			SettingsManager.hide_mouse()
		get_tree().paused = false
	
	if is_instance_valid(autopause_timer_2):
		Thunder._disconnect(autopause_timer_2.timeout, _autopause_toggle)
		autopause_timer_2 = null
	if is_instance_valid(autopause_timer):
		Thunder._disconnect(autopause_timer.timeout, _autopause_toggle)
		autopause_timer = null
	opened = false
	animation_player.play(&"init")
	v_box_container.move_selector(0, true)
	v_box_container.focused = false
	options.focused = false
	controls_scene.reset_menus()


func _physics_process(delta: float) -> void:
	if !opened: return
	if !get_tree().paused:
		get_tree().paused = true

var autopause_timer: SceneTreeTimer
var autopause_timer_2: SceneTreeTimer

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if !_can_autopause(): return
		if DisplayServer.window_can_draw() && !SettingsManager.settings.get("autopause", true): return
		if is_instance_valid(autopause_timer):
			Thunder._disconnect(autopause_timer.timeout, _autopause_toggle)
		autopause_timer = null
		autopause_timer = get_tree().create_timer(0.2)
		Thunder._connect(autopause_timer.timeout, _autopause_toggle, CONNECT_ONE_SHOT)
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		await get_tree().physics_frame
		if DisplayServer.window_can_draw():
			if is_instance_valid(autopause_timer):
				Thunder._disconnect(autopause_timer.timeout, _autopause_toggle)
			autopause_timer = null
			return
		if !_can_autopause(): return
		if is_instance_valid(autopause_timer_2):
			Thunder._disconnect(autopause_timer_2.timeout, _autopause_toggle)
		autopause_timer_2 = null
		autopause_timer_2 = get_tree().create_timer(0.2)
		Thunder._connect(autopause_timer_2.timeout, _autopause_toggle, CONNECT_ONE_SHOT)


func _autopause_toggle() -> void:
	if DisplayServer.window_can_draw() && !SettingsManager.settings.get("autopause", true):
		return
	if Scenes.current_scene.get(&"disable_pause_menu"):
		return
	if !opened:
		toggle(false, true)


func _can_autopause() -> bool:
	if !Scenes.current_scene is Level: return false
	if !&"game_over" in Scenes.custom_scenes: return false
	if opened || Scenes.custom_scenes.game_over.opened: return false
	if get_tree().paused: return false
	
	var pl = Thunder._current_player
	if pl && pl.completed:
		return false
	return true


func _on_scene_changed(to: Node) -> void:
	_no_unpause = false
	if to is Stage2D && SettingsManager.settings.autopause:
		await Scenes.current_scene.stage_ready
		var trans = TransitionManager.current_transition
		if trans:
			await TransitionManager.transition_end
			if !is_instance_valid(trans) || trans.cancelled || TransitionManager.current_transition != trans:
				return
		if !DisplayServer.window_is_focused():
			_autopause_toggle()
