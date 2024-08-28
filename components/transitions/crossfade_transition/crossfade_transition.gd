extends Transition

@export var fade_time: float = 0.54

@onready var texture_rect_from: TextureRect = $TextureRect
var _scene: String
var _forced_pause: bool

func _ready() -> void:
	name = "crossfade_transition"
	## print("[Transition] Making 'FROM' image...")
	#await RenderingServer.frame_post_draw
	var image: Image = GlobalViewport.vp.get_texture().get_image()
	
	texture_rect_from.texture = ImageTexture.create_from_image(image)
	start.emit()
	
	## print("[Transition] Going to scene...")
	Scenes.goto_scene(_scene)
	await Scenes.scene_ready
	get_tree().paused = true
	_forced_pause = true
	
	## print("[Transition] Done")
	middle.emit()
	var tw = create_tween()
	tw.tween_property(texture_rect_from, "self_modulate:a", 0.0, fade_time)
	tw.tween_callback(func():
		_forced_pause = false
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
