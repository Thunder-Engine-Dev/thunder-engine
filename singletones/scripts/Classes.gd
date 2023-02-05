# Singleton that merge some classes that could be called generally
# to prevent from large amount of icons displaying in Node dock
extends Node

# const CLASS_NAME:Script = preload("script path here!")


func _init():
	var autoload_list: Array = get_files("res://modules/", "preload.gd")
	if autoload_list.is_empty(): return
	
	for i in autoload_list:
		var node = Node.new()
		node.set_script(load(i))
		add_child(node)
		
		node.set_name(node.get_name())


func get_files(path: String, file := "", files := []):
	var dir = DirAccess.open(path)
	if dir == null || DirAccess.get_open_error() != OK:
		print("An error occurred when trying to access %s." % path)
		return
	
	dir.include_hidden = false
	dir.include_navigational = false
	dir.list_dir_begin()
	
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			files = get_files(dir.get_current_dir().path_join(file_name), file, files)
		else:
			if file != "" && file_name.get_file() != file:
				file_name = dir.get_next()
				continue
			
			files.append(dir.get_current_dir().path_join(file_name))
		
		file_name = dir.get_next()
	
	return files
