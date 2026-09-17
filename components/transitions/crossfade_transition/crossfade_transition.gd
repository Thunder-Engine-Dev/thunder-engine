extends Transition

const MIX_SHADER: Shader = preload("res://engine/components/transitions/crossfade_transition/bilinear_scaling_mix.gdshader")

@export var fade_time: float = 0.54

var _scene: String
var _forced_pause: bool
var _canvas_item_rid: RID
var _img_rid: RID
var _material: ShaderMaterial


func _init() -> void:
	switches_scene = true


func _ready() -> void:
	name = "crossfade_transition"
	
	var vp_rid := GlobalViewport.vp.get_viewport_rid()
	_img_rid = RenderingServer.texture_2d_create(
		RenderingServer.texture_2d_get(RenderingServer.viewport_get_texture(vp_rid))
	)
	
	_canvas_item_rid = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_default_texture_filter(
		_canvas_item_rid,
		int(GlobalViewport.container.texture_filter)
	)
	var parent_mat := GlobalViewport.container.material
	_material = parent_mat.duplicate() if parent_mat is ShaderMaterial else ShaderMaterial.new()
	_material.shader = MIX_SHADER
	RenderingServer.canvas_item_set_material(_canvas_item_rid, _material.get_rid())
	RenderingServer.canvas_item_set_parent(_canvas_item_rid, GlobalViewport.container.get_canvas_item())
	
	var rect := Rect2(Vector2.ZERO, GlobalViewport.vp.size)
	RenderingServer.canvas_item_add_texture_rect(_canvas_item_rid, rect, _img_rid)
	start.emit()
	
	Scenes.goto_scene(_scene)
	Thunder._connect(tree_exiting, _free_canvas_item, CONNECT_ONE_SHOT)
	await Scenes.scene_ready
	if cancelled || !is_inside_tree():
		return
	get_tree().paused = true
	_forced_pause = true
	
	middle.emit()
	var tw = create_tween()
	tw.tween_method(_set_canvas_modulate, Color.WHITE, Color(1, 1, 1, 0), fade_time)
	tw.tween_callback(_on_fade_finished)


func _set_canvas_modulate(value: Color) -> void:
	if _canvas_item_rid.is_valid():
		RenderingServer.canvas_item_set_modulate(_canvas_item_rid, value)


func _free_canvas_item() -> void:
	if _canvas_item_rid.is_valid():
		RenderingServer.free_rid(_canvas_item_rid)
		_canvas_item_rid = RID()
	if _img_rid.is_valid():
		RenderingServer.free_rid(_img_rid)
		_img_rid = RID()
	_material = null


func _on_fade_finished() -> void:
	if cancelled:
		return
	_forced_pause = false
	Thunder._disconnect(tree_exiting, _free_canvas_item)
	_free_canvas_item()
	get_tree().paused = false
	end.emit()


func _physics_process(_delta: float) -> void:
	if _forced_pause:
		get_tree().paused = true


func with_scene(scene: String) -> Transition:
	_scene = scene
	return self


func with_time(duration: float) -> Transition:
	fade_time = duration
	return self
