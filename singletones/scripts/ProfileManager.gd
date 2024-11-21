extends Node
## Class that can load and save profiles, as well as store them in memory.

class Profile:
	var name: String
	var data: Dictionary
	
	func has_completed(level_name: StringName) -> bool:
		if data.has(&"completed_levels"):
			return data.completed_levels.has(level_name)
		return false
	
	func complete_level(level_name: StringName) -> void:
		if !data.has(&"completed_levels"):
			data.completed_levels = []
		
		data.completed_levels.append(level_name)
	
	
	func has_completed_world(world_name: StringName) -> bool:
		if data.has(&"completed_worlds"):
			return data.completed_worlds.has(world_name)
		return false
	
	func complete_world(world_name: StringName) -> void:
		if !data.has(&"completed_worlds"):
			data.completed_worlds = []
		
		data.completed_worlds.append(world_name)
	
	
	func get_next_level_name() -> StringName:
		if data.has(&"next_level"):
			return data.next_level
		return &""
	
	func set_next_level_name(level_name: StringName) -> void:
		data.next_level = level_name
	
	
	func get_world_numbers() -> StringName:
		if data.has(&"world_numbers"):
			return data.world_numbers
		return &""
	
	func set_world_numbers(world: int, level: int) -> void:
		data.world_numbers = &"%d-%d" % [world, level]


var profiles: Dictionary
var current_profile: Profile

const SAVE_FILE_EX = ".ths"

func _ready() -> void:
	load_all_profiles()
	
	create_new_profile(&"debug")
	print("[Profile Manager] Dummy profile set for testing")


func load_all_profiles() -> void:
	if !DirAccess.dir_exists_absolute(&"user://saves/"):
		DirAccess.make_dir_absolute(&"user://saves/")
	
	var dir: DirAccess = DirAccess.open(&"user://saves/")
	profiles = {}
	
	for file in dir.get_files():
		if file.begins_with(&"debug"):
			continue
		if file.ends_with(SAVE_FILE_EX):
			file = file.trim_suffix(SAVE_FILE_EX)
			print("[Profile Manager] Loading ", file)
			var err: Error = load_profile(file)
			if err:
				printerr("[Profile Manager] %s has failed to load!" % file)
	
	print("[Profile Manager] All profiles loaded!")


func create_new_profile(_name: StringName) -> void:
	current_profile = Profile.new()
	current_profile.name = _name
	save_current_profile()
	profiles[_name] = current_profile
	
	print("[Profile Manager] Profile %s created!" % _name)

#func profile_exists(name: StringName) -> bool:
	#return FileAccess.file_exists("user://%s.ths" % name)

## Use this to set current profile
func set_current_profile(_name: StringName) -> bool:
	if profiles.has(_name):
		current_profile = profiles[_name]
		return false
	else:
		create_new_profile(_name)
		return true


func load_profile(_name: StringName) -> Error:
	var path: String = convert_to_path(_name)
	if !FileAccess.file_exists(path):
		create_new_profile(_name)
		return OK
	
	var data: String = FileAccess.get_file_as_string(path)
	var dict = JSON.parse_string(data)
	
	if dict == null:
		OS.alert("Failed to load save " + _name, "Can't load save file!")
		return ERR_INVALID_DATA
	
	var profile: Profile = Profile.new()
	profile.name = _name
	profile.data = dict
	
	profiles[_name] = profile
	return OK


func delete_profile(_name: StringName) -> void:
	var path: String = convert_to_path(_name)
	if !FileAccess.file_exists(path):
		return
	if profiles.has(_name):
		profiles.erase(_name)
	
	DirAccess.remove_absolute(path)
	print("[Profile Manager] Profile deleted!")


func save_current_profile() -> void:
	save_profile_data(current_profile.name, current_profile.data)


func save_profile_data(_name: StringName, _data: Dictionary) -> void:
	var data = JSON.stringify(_data)
	
	var file: FileAccess = FileAccess.open(
		convert_to_path(_name),
		FileAccess.WRITE
	)
	file.store_string(data)
	file = null
	print("[Profile Manager] Profile %s saved!" % _name)


func convert_to_path(file: StringName) -> StringName:
	if file.ends_with(SAVE_FILE_EX):
		file = "user://saves/%s" % [file]
	else:
		file = "user://saves/%s%s" % [file, SAVE_FILE_EX]
	
	return file
