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
		
		data[&"completed_levels"].append(level_name)

var profiles: Dictionary
var current_profile: Profile

const SAVE_FILE_EX = ".ths"

func _ready() -> void:
	if !DirAccess.dir_exists_absolute("user://saves/"):
		DirAccess.make_dir_absolute("user://saves/")
	
	var dir: DirAccess = DirAccess.open("user://saves/")
	
	for file in dir.get_files():
		if file.ends_with(SAVE_FILE_EX):
			print("[Profile Manager] Loading ", file)
			load_profile(file)
	
	print("[Profile Manager] All profiles loaded!")
	
	create_new_profile("debug")
	print("[Profile Manager] Dummy profile set for testing")

func create_new_profile(_name: StringName) -> void:
	current_profile = Profile.new()
	current_profile.name = _name
	save_current_profile()
	print("[Profile Manager] Profile ", _name, " created!")

#func profile_exists(name: StringName) -> bool:
	#return FileAccess.file_exists("user://%s.ths" % name)

## Use this to set current profile
func set_current_profile(_name: StringName) -> void:
	if profiles.has(_name):
		current_profile = profiles[_name]
	else:
		create_new_profile(_name)


func load_profile(_name: StringName) -> void:
	@warning_ignore("static_called_on_instance")
	var path: String = convert_to_path(_name)
	if !FileAccess.file_exists(path):
		create_new_profile(_name)
		return
	
	var data: String = FileAccess.get_file_as_string(path)
	var dict = JSON.parse_string(data)
	
	if dict == null:
		OS.alert("Failed to load save " + _name, "Can't load save file!")
		return
	
	var profile: Profile = Profile.new()
	profile.name = _name
	profile.data = dict
	
	profiles[name] = profile

func delete_profile(_name: StringName) -> void:
	@warning_ignore("static_called_on_instance")
	var path: String = convert_to_path(_name)
	if !FileAccess.file_exists(path):
		return
	
	DirAccess.remove_absolute(path)
	print("[Profile Manager] Profile deleted!")

func save_current_profile() -> void:
	var json: JSON = JSON.new()
	@warning_ignore("static_called_on_instance")
	var data = json.stringify(current_profile.data)
	
	@warning_ignore("static_called_on_instance")
	var file: FileAccess = FileAccess.open(convert_to_path(current_profile.name),FileAccess.WRITE)
	file.store_string(data)
	file.close()
	print("[Profile Manager] Profile %s saved!" % current_profile.name)

static func convert_to_path(file: StringName) -> StringName:
	if file.ends_with(SAVE_FILE_EX):
		file = "user://saves/%s" % [file]
	else:
		file = "user://saves/%s%s" % [file, SAVE_FILE_EX]
	
	return file
