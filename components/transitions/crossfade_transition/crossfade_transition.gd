extends Transition

@export var fade_time: float = 0.54

#@onready var texture_rect_from: TextureRect = $TextureRect
var _scene: String
var _forced_pause: bool

func _ready() -> void:
	name = "crossfade_transition"
	## print("[Transition] Making 'FROM' image...")
	#await RenderingServer.frame_post_draw
	#var image: Image = GlobalViewport.vp.get_texture().get_image()
	#texture_rect_from.texture = ImageTexture.create_from_image(image)
	
	var rs := RenderingServer
	var vp_rid := GlobalViewport.vp.get_viewport_rid()
	var img_rid: RID
	img_rid = rs.texture_2d_create(rs.texture_2d_get(rs.viewport_get_texture(vp_rid)))
	
	var canvas_item_rid := rs.canvas_item_create()
	rs.canvas_item_set_default_texture_filter(
		canvas_item_rid,
		RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST if !SettingsManager.settings.filter else \
		RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	)
	rs.canvas_item_set_parent(canvas_item_rid, GlobalViewport.container.get_canvas_item())
	
	var rect := Rect2(Vector2.ZERO, GlobalViewport.vp.size)
	rs.canvas_item_add_texture_rect(canvas_item_rid, rect, img_rid)
	start.emit()
	
	## print("[Transition] Going to scene...")
	Scenes.goto_scene(_scene)
	Thunder._connect(tree_exiting, rs.free_rid.bind(canvas_item_rid), CONNECT_ONE_SHOT)
	await Scenes.scene_ready
	get_tree().paused = true
	_forced_pause = true
	
	## print("[Transition] Done")
	middle.emit()
	var tw = create_tween()
	#tw.tween_property(texture_rect_from, "self_modulate:a", 0.0, fade_time)
	tw.tween_method(
		func(value: Color):
			rs.canvas_item_set_modulate(canvas_item_rid, value),
		Color.WHITE, Color(1, 1, 1, 0), fade_time
	)
	tw.tween_callback(func():
		_forced_pause = false
		rs.free_rid(canvas_item_rid)
		Thunder._disconnect(tree_exiting, rs.free_rid.bind(canvas_item_rid))
		get_tree().paused = false
		end.emit()
	)

func _physics_process(delta: float) -> void:
	if _forced_pause:
		get_tree().paused = true


func with_scene(scene: String) -> Transition:
	_scene = scene
	return self


func with_time(duration: float) -> Transition:
	fade_time = duration
	return self
