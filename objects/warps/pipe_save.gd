@icon("res://engine/objects/warps/icons/pipe_save.svg")
@tool
extends "pipe_in.gd"

@export
var profile_name: String

var deletion_progress: float

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
		else:
			deletion_progress = clampf(deletion_progress - delta, 0, 1)
		
	super(delta)

func delete_save() -> void:
	ProfileManager.delete_profile(profile_name)
	save_deleted.emit()

func pass_warp() -> void:
	ProfileManager.set_current_profile(profile_name)
	super()
