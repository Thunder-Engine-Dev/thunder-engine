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
		GlobalViewport.vp.get_texture().get_image().save_png("user://Screenshot.png")
		GlobalViewport.size = old_size
		GlobalViewport.vp.size = old_size
		if hud && old_visible:
			hud.visible = old_visible
		#cam.global_position = old_cam_pos
		#cam.offset = Vector2.ZERO
		#Console.get_tree().paused = old_paused
		GlobalViewport._update_view()
	, CONNECT_ONE_SHOT)
	
	return Command.ExecuteResult.new("Success; screenshot has been saved to %s" % [OS.get_user_data_dir()])
