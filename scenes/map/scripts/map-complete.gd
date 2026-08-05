extends Node2D

@export var goto_scene: String
@export var save_completed_world: bool = true
@export var world_name: String

var skippable: bool = false

func _ready() -> void:
	if Thunder.autosplitter.can_split_on("world_complete"):
		Thunder.autosplitter.split("Map Completed")
	if Data.values.get("map_force_selected_marker"):
		Data.values.map_force_go_next = true
	if save_completed_world && !ProfileManager.current_profile.has_completed_world(world_name):
		ProfileManager.current_profile.data.current_world = goto_scene
		ProfileManager.current_profile.complete_world(world_name)
		ProfileManager.save_current_profile()
		ProfileManager.profile_data_saved_user_display.emit(ProfileManager.current_profile.name)
	await get_tree().create_timer(1.0, true, false, true).timeout
	skippable = true
	
func _physics_process(delta: float) -> void:
	if !skippable: return
	if Input.is_action_pressed("m_jump") || Input.is_action_pressed("ui_accept"):
		skippable = false
		Audio.stop_music_channel(1, true)
		TransitionManager.accept_transition(
			load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
				.instantiate()
				.with_speeds(0.01, -0.1)
		)
		
		TransitionManager.transition_middle.connect(
			_on_transition_middle_goto_next,
			CONNECT_ONE_SHOT
		)


func _on_transition_middle_goto_next() -> void:
	TransitionManager.current_transition.paused = true
	Scenes.goto_scene(goto_scene)
	Scenes.scene_changed.connect(_on_scene_changed_unpause_transition, CONNECT_ONE_SHOT)


static func _on_scene_changed_unpause_transition(_current_scene: Node) -> void:
	var trans := TransitionManager.current_transition
	if is_instance_valid(trans):
		trans.paused = false
