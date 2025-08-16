extends Command

static func register() -> Command:
	return new().set_name("screenshot") \
	.set_description("Save a screenshot of a current Camera Area. Recommended to stay at the top left corner. Note that this may break things in-game.")

func execute(args:Array) -> Command.ExecuteResult:
	var cam: Camera2D = Thunder._current_camera
	if !cam:
		return Command.ExecuteResult.new("ERROR: Camera does not exist")
	
	var area: Control = cam.get_meta(&"cam_area")
	if !area:
		return Command.ExecuteResult.new("ERROR: Camera has no area")
	
	var old_size = GlobalViewport.vp.size
	#var old_cam_pos = cam.global_position
	var old_visible
	#var old_paused = Console.get_tree().paused
	#Console.get_tree().paused = true
	#GlobalViewport.size.x = area.size
	GlobalViewport.size = area.size
	GlobalViewport.vp.size = area.size
	var hud = Thunder._current_hud
	if hud:
		old_visible = hud.visible
		hud.visible = false
	
	#cam.global_position = (cam.get_viewport_rect().size / 2)
	#cam.offset = area.get_rect().position + (area.get_viewport_rect().size / 2)
	
	RenderingServer.frame_post_draw.connect(func():
		if !DirAccess.dir_exists_absolute("user://screenshots"):
			DirAccess.make_dir_absolute("user://screenshots")
		var filename := get_unique_filename("user://screenshots", "Screenshot_", ".png")
		GlobalViewport.vp.get_texture().get_image().save_png(filename)
		GlobalViewport.size = old_size
		GlobalViewport.vp.size = old_size
		if hud && old_visible:
			hud.visible = old_visible
		#cam.global_position = old_cam_pos
		#cam.offset = Vector2.ZERO
		#Console.get_tree().paused = old_paused
		GlobalViewport._update_view()
	, CONNECT_ONE_SHOT)
	
	return Command.ExecuteResult.new("Success. [url=%s]Open directory with the image[/url]" % [
		OS.get_user_data_dir().path_join("screenshots")
	])

func get_unique_filename(base_path: String, base_name: String, extension: String) -> String:
	var counter: int = 1
	var file_path: String = base_path + "/" + base_name + str(counter) + extension

	while FileAccess.file_exists(file_path):
		counter += 1
		file_path = base_path + "/" + base_name + str(counter) + extension
		
	return file_path
