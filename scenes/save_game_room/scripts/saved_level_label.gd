extends Label

@export_multiline var empty_text: String = "empty..."
@onready var pipe_save: Area2D = $".."
@onready var _tweak: bool = SettingsManager.get_tweak("load_save_from_world_start", false)
@onready var text_template: String = text

func _ready() -> void:
	pipe_save.save_deleted.connect(set_empty)
	update_label()


func update_label() -> void:
	if !pipe_save.profile_name:
		set_empty()
		return
	
	var profile_name = pipe_save.profile_name

	if ProfileManager.profiles.has(profile_name):
		var prof: ProfileManager.Profile = ProfileManager.profiles[profile_name]
		
		var full_numbers: String = prof.get_world_numbers()
		var world_numbers: Array = full_numbers.split("-")
		if !world_numbers[0]:
			set_empty()
			return
		
		pipe_save.is_empty = false
		if world_numbers.size() < 2: world_numbers.append("0")
		if _tweak:
			full_numbers = world_numbers[0]
		
		text = text_template % full_numbers.replace("-", " - ")
	else:
		set_empty()


func set_empty() -> void:
	text = empty_text
	pipe_save.is_empty = true


func set_world_numbers(world_numbers: String) -> void:
	if _tweak:
		world_numbers = world_numbers.get_slice("-", 0)
	text = text_template % world_numbers.replace("-", " - ")
	pipe_save.is_empty = false
