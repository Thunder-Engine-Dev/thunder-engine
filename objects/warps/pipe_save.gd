@icon("res://engine/objects/warps/icons/pipe_save.svg")
@tool
extends "pipe_in.gd"

@export
var profile_name: String

var deletion_progress: float
@onready var _tweak: bool = SettingsManager.get_tweak("load_save_from_world_start", false)

signal save_deleted

func _ready() -> void:
	super()
	player_exit.connect(func(): deletion_progress = 0)

func _physics_process(delta: float) -> void:
	if player != null:
		if Input.is_action_pressed(&"a_delete"):
			deletion_progress = clampf(deletion_progress + delta / 3, 0, 1)
			if deletion_progress == 1:
				delete_save()
				deletion_progress = 0.0
		else:
			deletion_progress = clampf(deletion_progress - delta, 0, 1)
		
	super(delta)

func delete_save() -> void:
	ProfileManager.delete_profile(profile_name)
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
