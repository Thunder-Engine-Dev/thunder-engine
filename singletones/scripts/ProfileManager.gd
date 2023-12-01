extends Node

class Profile:
	var name: String
	var data: Dictionary
	
	func has_completed(level_name: StringName) -> bool:
		if data.has(&"completed_levels"):
			return data[&"completed_levels"].has(level_name)
		return false
	
	func complete_level(level_name: StringName) -> void:
		if !data.has(&"completed_levels"):
			data[&"completed_levels"] = []
		
		data[&"completed_levels"].push(level_name)
	
	

var current_profile: Profile

func create_new_profile(name: StringName) -> void:
	current_profile = Profile.new()
	current_profile.name = name
	

func load_profile(name: StringName) -> void:
	var path: String = "user://%s.ths" % name
	if !FileAccess.file_exists(path):
		create_new_profile(name)
		return
	
	var data: String = FileAccess.get_file_as_string(path)
	var dict = JSON.parse_string(data)
	
	var profile: Profile = Profile.new()
	profile.name = name
	profile.data = dict
	
	current_profile = profile


func save_current_profile() -> void:
	var json: JSON = JSON.new()
	var data = json.stringify(current_profile.data)
	
	var file: FileAccess = FileAccess.open("user://%s.ths" % current_profile.name,FileAccess.WRITE)
	file.store_string(data)
	file.close()

