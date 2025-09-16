@icon("res://engine/objects/warps/icons/pipe_save.svg")
@tool
extends "pipe_in.gd"

@export
var profile_name: String

var deletion_progress: float
var is_empty: bool
var _tweak: bool

@onready var faster_deletion_tw = SettingsManager.get_tweak("faster_save_deletion", false)

signal save_deleted

func _ready() -> void:
	super()
	if Engine.is_editor_hint(): return
	_tweak = SettingsManager.get_tweak("load_save_from_world_start", false)
	player_exit.connect(func(): deletion_progress = 0)


func _physics_process(delta: float) -> void:
	_deletion_process(delta)
	super(delta)


func _deletion_process(delta: float) -> void:
	if player != null:
		if Input.is_action_pressed(&"a_delete"):
			var mod_delta: float = delta / 3
			if faster_deletion_tw:
				mod_delta = delta / 0.6
			deletion_progress = clampf(deletion_progress + mod_delta, 0, 1)
			if deletion_progress == 1:
				delete_save()
				deletion_progress = 0.0
		else:
			deletion_progress = clampf(deletion_progress - delta, 0, 1)


func delete_save() -> void:
	ProfileManager.delete_profile(profile_name)
	if ProfileManager.profiles.has("suspended") && ProfileManager.profiles.suspended.data.get("saved_profile") == profile_name:
		ProfileManager.delete_profile("suspended")
	save_deleted.emit()
	print(&"Save " + profile_name + &" deleted!")
	Audio.play_1d_sound(preload("res://engine/objects/bumping_blocks/_sounds/break.wav"))


func pass_warp() -> void:
	ProfileManager.set_current_profile(profile_name)
	if _tweak:
		ProfileManager.current_profile.data.completed_levels = []
	target = null
	if &"current_world" in ProfileManager.current_profile.data && ProfileManager.current_profile.data.current_world:
		warp_to_scene = ProfileManager.current_profile.data.current_world
	await get_tree().physics_frame
	super()
