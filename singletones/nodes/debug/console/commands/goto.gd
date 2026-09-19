extends Command

static func register() -> Command:
	return new().set_name("goto").add_param("scene_path", TYPE_STRING).set_debug().set_description("Changes current scene to a specified scene.")

func execute(args:Array) -> Command.ExecuteResult:
	var scene = " ".join(args)
	var packed_scene: PackedScene = load(scene)
	if packed_scene && packed_scene.can_instantiate():
		Scenes.pre_scene_changed.emit()
		Scenes.load_scene_from_packed.call_deferred(packed_scene)
		return Command.ExecuteResult.new("Success")

	return Command.ExecuteResult.new("[color=red]Invalid Scene[/color]")


func joins_arguments() -> bool:
	return true


func get_completion_args(current_args: PackedStringArray, cycling_from_args: PackedStringArray) -> PackedStringArray:
	if cycling_from_args.is_empty():
		return current_args
	var old_path: String = " ".join(cycling_from_args).strip_edges()
	var cur_path: String = " ".join(current_args).strip_edges()
	if "/" in old_path && !cur_path.ends_with("/"):
		return cycling_from_args
	return current_args


func get_argument_options(args: PackedStringArray, index: int) -> Array:
	var typed: String = " ".join(args).strip_edges()
	var slash_idx: int = typed.rfind("/")
	if slash_idx < 0:
		if typed.is_empty() || "res://".begins_with(typed):
			return [_completion_token("res://", typed)]
		return []
	
	var dir_path: String = typed.left(slash_idx + 1)
	var name_prefix: String = typed.substr(slash_idx + 1)
	if !dir_path.begins_with("res://") || !DirAccess.dir_exists_absolute(dir_path):
		return []
	
	var folders: PackedStringArray = DirAccess.get_directories_at(dir_path)
	var files: PackedStringArray = DirAccess.get_files_at(dir_path)
	folders.sort()
	files.sort()
	
	var folder_paths: Array[String] = []
	var file_paths: Array[String] = []
	for folder: String in folders:
		if folder.begins_with(".") || !folder.begins_with(name_prefix):
			continue
		if !_dir_has_scenes_or_folders(dir_path + folder):
			continue
		folder_paths.append(dir_path + folder)
	for file: String in files:
		var scene_name: String = file.trim_suffix(".remap")
		if !scene_name.ends_with(".tscn") || !scene_name.begins_with(name_prefix):
			continue
		file_paths.append(dir_path + scene_name)
	
	if folder_paths.size() == 1 && file_paths.is_empty():
		folder_paths[0] += "/"
	
	var result: Array = []
	for folder_path: String in folder_paths:
		result.append(_completion_token(folder_path, typed))
	for file_path: String in file_paths:
		result.append(_completion_token(file_path, typed))
	return result


func _dir_has_scenes_or_folders(path: String) -> bool:
	for folder: String in DirAccess.get_directories_at(path):
		if !folder.begins_with("."):
			return true
	for file: String in DirAccess.get_files_at(path):
		if file.trim_suffix(".remap").ends_with(".tscn"):
			return true
	return false


func _completion_token(full_path: String, typed: String) -> String:
	var space_idx: int = typed.rfind(" ")
	if space_idx < 0:
		return full_path
	return full_path.substr(space_idx + 1)
