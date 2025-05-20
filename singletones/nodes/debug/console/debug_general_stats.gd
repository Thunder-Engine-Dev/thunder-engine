extends Label

var target_text: String


func _physics_process(delta: float) -> void:
	visible = Console.cv.general_stats_shown
	if !Console.cv.general_stats_shown: return
	@warning_ignore("incompatible_ternary")
	var other_text: String = "PAUSE:" + str(get_tree().paused) + \
		" TRANS:" + str(
			TransitionManager.current_transition.name if is_instance_valid(TransitionManager.current_transition) else "None"
		)
	
	var place_arr: Array = [
		_get_value_path(Scenes.current_scene, &"scene_file_path"),
		_get_value_path(Scenes.current_scene, &"jump_to_scene"),
		_get_value_path(Scenes._current_scene_buffer, &"resource_path"),
		Scenes.get_scene_path(Scenes.previous_scene_path),
		ProfileManager.current_profile.name if ProfileManager.current_profile else "null",
		str(Data.values.onetime_blocks),
	]
	
	@warning_ignore("incompatible_ternary")
	target_text = """
SC-CRNT: %s
SC-NEXT: %s
SC-BUFR: %s
SC-PREV: %s
PROFILE: %s,
DATA_1TIME: %s
""" % place_arr
	text = other_text + target_text

func _get_bool_mono(obj: Object, property: String) -> String:
	var _prop: Variant = obj.get(property)
	return str(_prop) if !_prop else (str(_prop) + " ")

func _get_value_path(value: Object, property: StringName) -> String:
	if !is_instance_valid(value): return "null"
	var _out = value.get(property)
	return Scenes.get_scene_path(_out) if _out != null else "null"
