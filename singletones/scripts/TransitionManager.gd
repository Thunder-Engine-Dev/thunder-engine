extends Node
## This class acts as a transition manager and should be used in transitions internally

const BUILTIN_TRANSITIONS: Dictionary = {
	&"circle": "res://engine/components/transitions/circle_transition/circle_transition.tscn",
	&"crossfade": "res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn",
	&"fade": "res://engine/components/transitions/fade_transition/fade_transition.tscn",
	&"blur": "res://engine/components/transitions/blur_transition/blur_transition.tscn",
}

var current_transition: Transition
var _transitions: Dictionary = BUILTIN_TRANSITIONS.duplicate()

signal transition_start
signal transition_middle
signal transition_end

func accept_transition(trans: Transition) -> void:
	clear_transition()
	
	if trans.correct_aspect_ratio:
		GlobalViewport.center_container.add_child(trans)
	else:
		GlobalViewport.add_child(trans)
	
	current_transition = trans
	
	trans.start.connect(func():
		transition_start.emit()
	)
	trans.middle.connect(func():
		transition_middle.emit()
	)
	trans.end.connect(func():
		transition_end.emit()
		if current_transition == trans:
			current_transition = null
		trans.queue_free()
	)


## Immediately stops and removes [member current_transition].[br]
## The old overlay is taken out of the tree this frame (not [method Node.queue_free]
## only), so a new circle cannot share its shader state or draw over it for a frame.[br]
## [signal transition_middle] is [b]not[/b] emitted, so leftover
## [code]await TransitionManager.transition_middle[/code] callers do not follow the
## cancelled transition. Direct [code]await trans.middle[/code] callers are woken
## and must ignore the signal when [member Transition.cancelled] is true.
func clear_transition() -> void:
	if !is_instance_valid(current_transition):
		current_transition = null
		return
	var trans := current_transition
	current_transition = null
	_disconnect_all(trans.start)
	_disconnect_all(trans.middle)
	_disconnect_all(trans.end)
	trans.cancel()
	# Wake [code]await trans.middle[/code] without re-emitting [signal transition_middle].
	if is_instance_valid(trans):
		trans.middle.emit()


func _disconnect_all(sig: Signal) -> void:
	for conn in sig.get_connections():
		if sig.is_connected(conn.callable):
			sig.disconnect(conn.callable)


## Registers a custom transition scene under [param id] for use with
## [method create_transition] / [method Scenes.goto_scene_with_transition].
func register_transition(id: StringName, scene_path: String) -> void:
	_transitions[id] = scene_path


## Instantiates a transition by id.[br]
## Built-in ids: [code]&"circle"[/code], [code]&"crossfade"[/code],
## [code]&"fade"[/code], [code]&"blur"[/code].[br]
## [code]&"auto"[/code] picks crossfade or circle based on the settings tweak.
func create_transition(id: StringName = &"auto") -> Transition:
	if id == &"auto":
		id = &"crossfade" if _is_crossfade_enabled() else &"circle"
	if !_transitions.has(id):
		push_error("[TransitionManager] Unknown transition id: %s" % id)
		id = &"circle"
	return (load(_transitions[id]) as PackedScene).instantiate()


## Resolves [param transition] into a [Transition] instance.[br]
## Accepts a [Transition], a [StringName]/[String] id, or a [Callable] used as
## configuration for the auto-selected non-crossfade transition.
func _resolve_transition(transition: Variant, configure: Callable = Callable()) -> Transition:
	var config := configure
	var id_or_instance: Variant = transition
	
	if transition is Callable:
		config = transition
		id_or_instance = &"auto"
	
	var trans: Transition
	if id_or_instance is Transition:
		trans = id_or_instance
	elif id_or_instance is StringName or id_or_instance is String:
		trans = create_transition(StringName(id_or_instance))
	else:
		push_error("[TransitionManager] Invalid transition argument: %s" % type_string(typeof(id_or_instance)))
		trans = create_transition(&"auto")
	
	# Circle-style config (with_speeds, with_pause, ...) does not apply to
	# transitions that switch the scene themselves (crossfade).
	if config.is_valid() && !trans.switches_scene:
		config.call(trans)
	
	return trans


func _is_crossfade_enabled() -> bool:
	return SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)
