extends Label

@onready var pipe_save: Area2D = $".."

func _ready() -> void:
	if !pipe_save.profile_name:
		set_empty()
		return
	
	var profile_name = pipe_save.profile_name
	pipe_save.save_deleted.connect(set_empty)

	if ProfileManager.profiles.has(profile_name):
		var prof: ProfileManager.Profile = ProfileManager.profiles[profile_name]
		
		var full_numbers: String = prof.get_world_numbers()
		var world_numbers: Array = full_numbers.split("-")
		if !world_numbers:
			set_empty()
			return
		
		if world_numbers.size() < 2: world_numbers.append("0")
		
		if world_numbers:
			text = text % full_numbers.replace("-", " - ")
	else:
		set_empty()


func set_empty() -> void:
	text = "empty..."
	
